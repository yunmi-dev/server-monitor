// tests/api/logs.rs
use actix_web::{test, web, App};
use chrono::{Duration, Utc};
use serde_json::json;
use uuid::Uuid;
use mockall::predicate::*; 
use mockall::mock;
use mockall::predicate;

use rust_server::{
    api::{logs::*, response::ApiResponse},
    models::logs::{LogLevel, LogEntry, LogFilter, CreateLogRequest},
};


mock! {
    Repository {
        async fn create_log(&self, log: LogEntry) -> anyhow::Result<LogEntry>;
        async fn get_logs(&self, filter: LogFilter) -> anyhow::Result<Vec<LogEntry>>;
        async fn get_log(&self, id: &str) -> anyhow::Result<Option<LogEntry>>;
        async fn delete_logs(&self, filter: LogFilter) -> anyhow::Result<i64>;
    }
}

#[actix_rt::test]
async fn test_create_log() {
    let mut mock_repo = MockRepository::new();
    let test_id = Uuid::new_v4().to_string();
    let now = Utc::now();

    mock_repo
        .expect_create_log()
        .with(predicate::function(|log: &LogEntry| {
            log.level == LogLevel::Info &&
            log.message == "Test message" &&
            log.component == "test-component"
        }))
        .times(1)
        .returning(move |log| Ok(LogEntry {
            id: test_id.clone(),
            timestamp: now,
            ..log
        }));

    let create_request = CreateLogRequest {
        level: LogLevel::Info,
        message: "Test message".to_string(),
        component: "test-component".to_string(),
        server_id: Some("test-server".to_string()),
        metadata: Some(json!({
            "key": "value"
        }).as_object().unwrap().iter().map(|(k, v)| (k.clone(), v.clone())).collect()),
        stack_trace: None,
        source_location: None,
    };

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/logs", web::post().to(create_log)),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/logs")
        .set_json(&create_request)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<LogEntry> = test::read_body_json(resp).await;
    assert!(body.success);
    let created_log = body.data.unwrap();
    assert_eq!(created_log.message, "Test message");
    assert_eq!(created_log.component, "test-component");
    assert_eq!(created_log.level, LogLevel::Info);
}

#[actix_rt::test]
async fn test_get_logs_with_filter() {
    let mut mock_repo = MockRepository::new();
    let test_logs = vec![
        LogEntry::new(
            LogLevel::Info,
            "Test log 1".to_string(),
            "test-component".to_string(),
            Some("test-server".to_string()),
        ),
        LogEntry::new(
            LogLevel::Warning,
            "Test log 2".to_string(),
            "test-component".to_string(),
            Some("test-server".to_string()),
        ),
    ];

    mock_repo
        .expect_get_logs()
        .times(1)
        .returning(move |_| Ok(test_logs.clone()));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/logs", web::get().to(get_logs)),
    )
    .await;

    let filter = LogFilter {
        levels: Some(vec![LogLevel::Info, LogLevel::Warning]),
        from: Some(Utc::now() - Duration::hours(1)),
        to: Some(Utc::now()),
        server_id: Some("test-server".to_string()),
        component: Some("test-component".to_string()),
        search: None,
        limit: Some(10),
        offset: Some(0),
    };

    // serde_qs 의존성 추가 필요 (Cargo.toml에 추가)
    // serde_qs = "0.8"
    let resp = test::TestRequest::get()
        .uri(&format!("/logs?{}", serde_qs::to_string(&filter).unwrap()))
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<Vec<LogEntry>> = test::read_body_json(resp).await;
    assert!(body.success);
    assert_eq!(body.data.unwrap().len(), 2);
}

// 소유권 문제 해결못함
#[actix_rt::test]
async fn test_get_specific_log() {
    let mut mock_repo = MockRepository::new();
    let test_log = LogEntry::new(
        LogLevel::Info,
        "Test log".to_string(),
        "test-component".to_string(),
        Some("test-server".to_string()),
    );

    mock_repo
        .expect_get_log()
        .returning(move |_| Ok(Some(test_log.clone())));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/logs/{id}", web::get().to(get_log)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/logs/any-id")
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<LogEntry> = test::read_body_json(resp).await;
    assert!(body.success);
}

#[actix_rt::test]
async fn test_delete_logs() {
    let mut mock_repo = MockRepository::new();
    
    mock_repo
        .expect_delete_logs()
        .times(1)
        .returning(|_| Ok(5));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/logs", web::delete().to(delete_logs)),
    )
    .await;

    let filter = LogFilter {
        server_id: Some("test-server".to_string()),
        levels: Some(vec![LogLevel::Warning]),
        ..Default::default()
    };

    let resp = test::TestRequest::delete()
        .uri("/logs")
        .set_json(&filter)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<i64> = test::read_body_json(resp).await;
    assert!(body.success);
    assert_eq!(body.data.unwrap(), 5);
}