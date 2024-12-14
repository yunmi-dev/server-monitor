// tests/db/repository.rs
use chrono::{Duration, Utc};
use rust_server::db::models::*;
use rust_server::models::logs::{LogLevel, LogEntry, LogFilter};
use uuid::Uuid;
use serde_json::json;
use mockall::mock;
use chrono::DateTime;

mock! {
    Repository {
        fn new() -> Self;
        
        // Server operations
        async fn create_server(&self, server: Server) -> anyhow::Result<Server>;
        async fn get_server(&self, id: &str) -> anyhow::Result<Option<Server>>;
        async fn list_servers(&self) -> anyhow::Result<Vec<Server>>;
        async fn delete_server(&self, id: &str) -> anyhow::Result<()>;
        
        // Metrics operations
        async fn save_metrics(&self, metrics: MetricsSnapshot) -> anyhow::Result<()>;
        async fn get_server_metrics(&self, server_id: &str, from: DateTime<Utc>, to: DateTime<Utc>) -> anyhow::Result<Vec<MetricsSnapshot>>;
        
        // Log operations
        async fn create_log(&self, log: LogEntry) -> anyhow::Result<LogEntry>;
        async fn get_log(&self, id: &str) -> anyhow::Result<Option<LogEntry>>;
        async fn get_logs(&self, filter: LogFilter) -> anyhow::Result<Vec<LogEntry>>;
        async fn delete_logs(&self, filter: LogFilter) -> anyhow::Result<i64>;
        
        // Alert operations
        async fn create_alert(&self, alert: Alert) -> anyhow::Result<Alert>;
        async fn get_unacknowledged_alerts(&self) -> anyhow::Result<Vec<Alert>>;
        async fn acknowledge_alert(&self, alert_id: i64) -> anyhow::Result<()>;
        
        // User operations
        async fn create_user(&self, user: User) -> anyhow::Result<User>;
        async fn get_user_by_email(&self, email: &str) -> anyhow::Result<Option<User>>;
        async fn update_user(&self, user: User) -> anyhow::Result<User>;
    }
}

#[tokio::test]
async fn test_server_operations() {
    let mut mock_repo = MockRepository::new();
    let test_server = Server {
        id: Uuid::new_v4().to_string(),
        name: "Test Server".to_string(),
        hostname: "test.server.com".to_string(),
        port: 22,
        username: "testuser".to_string(),
        encrypted_password: "encrypted".to_string(),
        server_type: ServerType::Linux,
        category: ServerCategory::Virtual,
        created_by: Some("test-user".to_string()),
        ..Default::default()
    };

    let test_server_clone = test_server.clone();
    mock_repo
        .expect_create_server()
        .returning(move |server| Ok(server));

    mock_repo
        .expect_list_servers()
        .returning(move || Ok(vec![test_server_clone.clone()]));

    mock_repo
        .expect_get_server()
        .returning(|_| Ok(Some(test_server.clone())));

    mock_repo
        .expect_delete_server()
        .returning(|_| Ok(()));

    // Test server creation
    let result = mock_repo.create_server(test_server.clone()).await;
    assert!(result.is_ok());
    
    // Test server listing
    let result = mock_repo.list_servers().await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().len(), 1);

    // Test server retrieval
    let result = mock_repo.get_server(&test_server.id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().unwrap().id, test_server.id);

    // Test server deletion
    let result = mock_repo.delete_server(&test_server.id).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_metrics_storage() {
    let mut mock_repo = MockRepository::new();
    let test_snapshot = MetricsSnapshot {
        id: 0,
        server_id: Uuid::new_v4().to_string(),
        cpu_usage: 50.0,
        memory_usage: 70.0,
        disk_usage: 60.0,
        network_rx: 1000,
        network_tx: 2000,
        processes: json!([{
            "pid": 1,
            "name": "test-process",
            "cpu_usage": 10.0,
            "memory_usage": 1024
        }]),
        timestamp: Utc::now(),
    };

    mock_repo
        .expect_save_metrics()
        .returning(|_| Ok(()));

    mock_repo
        .expect_get_server_metrics()
        .returning(|_, _, _| Ok(vec![]));

    let result = mock_repo.save_metrics(test_snapshot.clone()).await;
    assert!(result.is_ok());

    let now = Utc::now();
    let one_hour_ago = now - Duration::hours(1);
    let result = mock_repo.get_server_metrics(&test_snapshot.server_id, one_hour_ago, now).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_log_management() {
    let mut mock_repo = MockRepository::new();
    let test_log = LogEntry {
        id: Uuid::new_v4().to_string(),
        level: LogLevel::Info,
        message: "Test log message".to_string(),
        component: "test-component".to_string(),
        server_id: None,
        timestamp: Utc::now(),
        metadata: Default::default(),
        stack_trace: None,
        source_location: None,
        correlation_id: None,
    };

    // Setup expectations
    mock_repo
        .expect_create_log()
        .returning(|log| Ok(log));

    mock_repo
        .expect_get_log()
        .returning(|_| Ok(Some(test_log.clone())));

    mock_repo
        .expect_get_logs()
        .returning(|_| Ok(vec![test_log.clone()]));

    mock_repo
        .expect_delete_logs()
        .returning(|_| Ok(5)); // 5 deleted logs

    // Test log creation
    let result = mock_repo.create_log(test_log.clone()).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().message, "Test log message");

    // Test log retrieval
    let result = mock_repo.get_log(&test_log.id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().unwrap().id, test_log.id);

    // Test log filtering
    let filter = LogFilter {
        levels: Some(vec![LogLevel::Info]),
        from: Some(Utc::now() - Duration::hours(1)),
        to: Some(Utc::now()),
        component: Some("test-component".to_string()),
        ..Default::default()
    };

    let result = mock_repo.get_logs(filter.clone()).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().len(), 1);

    // Test log deletion
    let result = mock_repo.delete_logs(filter).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), 5);
}

#[tokio::test]
async fn test_alert_handling() {
    let mut mock_repo = MockRepository::new();
    let test_alert = Alert {
        id: 0,
        server_id: Uuid::new_v4().to_string(),
        alert_type: "high_cpu_usage".to_string(),
        severity: AlertSeverity::Critical,
        message: "CPU usage exceeded 90%".to_string(),
        created_at: Utc::now(),
        acknowledged_at: None,
        acknowledged_by: None,
    };

    // Setup expectations
    mock_repo
        .expect_create_alert()
        .returning(|alert| Ok(alert));

    mock_repo
        .expect_get_unacknowledged_alerts()
        .returning(|| Ok(vec![test_alert.clone()]));

    mock_repo
        .expect_acknowledge_alert()
        .returning(|_| Ok(()));

    // Test alert creation
    let result = mock_repo.create_alert(test_alert.clone()).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().alert_type, "high_cpu_usage");

    // Test unacknowledged alerts retrieval
    let result = mock_repo.get_unacknowledged_alerts().await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().len(), 1);

    // Test alert acknowledgment
    let alert_id = 1;
    let result = mock_repo.acknowledge_alert(alert_id).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_user_management() {
    let mut mock_repo = MockRepository::new();
    let test_user = User {
        id: Uuid::new_v4().to_string(),
        email: "test@example.com".to_string(),
        password_hash: Some("hashed_password".to_string()),
        name: "Test User".to_string(),
        role: UserRole::User,
        provider: AuthProvider::Email,
        profile_image_url: None,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        last_login_at: Some(Utc::now()),
    };

    // Setup expectations
    mock_repo
        .expect_create_user()
        .returning(|user| Ok(user));

    mock_repo
        .expect_get_user_by_email()
        .returning(|_| Ok(Some(test_user.clone())));

    mock_repo
        .expect_update_user()
        .returning(|user| Ok(user));

    // Test user creation
    let result = mock_repo.create_user(test_user.clone()).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().email, "test@example.com");

    // Test user retrieval by email
    let result = mock_repo.get_user_by_email(&test_user.email).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().unwrap().id, test_user.id);

    // Test user update
    let result = mock_repo.update_user(test_user.clone()).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().id, test_user.id);
}