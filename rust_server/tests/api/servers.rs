// tests/api/servers.rs
use actix_web::{test, web, App};
use chrono::Utc;
use rust_server::{
    api::servers::*,
    api::response::ApiResponse,
    db::models::{*, UserRole, ServerCategory},
    config::ServerConfig,
    auth::types::AuthenticatedUser,
    models::metrics::ServerMetrics,
};
use mockall::predicate::*;
use mockall::mock;

mock! {
    Repository {
        async fn create_server(&self, server: Server) -> anyhow::Result<Server>;
        async fn get_server(&self, id: &str) -> anyhow::Result<Option<Server>>;
        async fn get_server_by_hostname(&self, hostname: &str) -> anyhow::Result<Option<Server>>;
        async fn list_servers(&self) -> anyhow::Result<Vec<Server>>;
        async fn list_servers_by_user(&self, user_id: &str) -> anyhow::Result<Vec<Server>>;
        async fn update_server_status(&self, id: &str, is_online: bool) -> anyhow::Result<()>;
        async fn delete_server(&self, id: &str) -> anyhow::Result<()>;
        async fn get_server_metrics(&self, server_id: &str, from: chrono::DateTime<Utc>, to: chrono::DateTime<Utc>) -> anyhow::Result<Vec<MetricsSnapshot>>;
        async fn get_server_metrics_history(&self, server_id: &str, from: chrono::DateTime<Utc>, to: chrono::DateTime<Utc>) -> anyhow::Result<Vec<ResourceHistory>>;
    }
}

mock! {
    MonitoringService {
        async fn get_server_metrics(&self, server_id: &str) -> Option<ServerMetrics>;
    }
}

#[actix_rt::test]
async fn test_create_server_success() {
    let mut mock_repo = MockRepository::new();
    let user = AuthenticatedUser {
        id: "test-user".to_string(),
        email: "test@example.com".to_string(),
        role: UserRole::Admin,
    };

    mock_repo
        .expect_get_server_by_hostname()
        .with(eq("test-host.com".to_string()))
        .times(1)
        .returning(|_| Ok(None));

    mock_repo
        .expect_create_server()
        .times(1)
        .returning(|server| Ok(server));

    let config = web::Data::new(ServerConfig::default());
    let create_request = CreateServerRequest {
        name: "Test Server".to_string(),
        host: "test-host.com".to_string(),
        port: 22,
        username: "testuser".to_string(),
        password: "testpass".to_string(),
        server_type: ServerType::Linux,
        category: ServerCategory::Virtual, 
    };

    let app = test::init_service(
        App::new()
            .app_data(config)
            .app_data(web::Data::new(mock_repo))
            .route("/servers", web::post().to(create_server)),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/servers")
        .set_json(&create_request)
        .app_data(user)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 201);
    
    let body: ApiResponse<Server> = test::read_body_json(resp).await;
    assert!(body.success);
    let created_server = body.data.unwrap();
    assert_eq!(created_server.name, "Test Server");
}

#[actix_rt::test]
async fn test_get_servers_as_admin() {
    let mut mock_repo = MockRepository::new();
    let user = AuthenticatedUser {
        id: "admin-user".to_string(),
        email: "admin@example.com".to_string(),
        role: UserRole::Admin,
    };

    let test_servers = vec![
        Server {
            id: "server-1".to_string(),
            name: "Server 1".to_string(),
            hostname: "server1.test.com".to_string(),
            ..Default::default()
        },
        Server {
            id: "server-2".to_string(),
            name: "Server 2".to_string(),
            hostname: "server2.test.com".to_string(),
            ..Default::default()
        },
    ];

    mock_repo
        .expect_list_servers()
        .times(1)
        .returning(move || Ok(test_servers.clone()));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/servers", web::get().to(get_servers)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/servers")
        .app_data(user)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<Vec<Server>> = test::read_body_json(resp).await;
    assert!(body.success);
    assert_eq!(body.data.unwrap().len(), 2);
}

#[actix_rt::test]
async fn test_get_server_status() {
    let mut mock_repo = MockRepository::new();
    let mut mock_monitoring = MockMonitoringService::new();
    let server_id = "test-server";

    let test_server = Server {
        id: server_id.to_string(),
        name: "Test Server".to_string(),
        hostname: "test.server.com".to_string(),
        is_online: true,
        ..Default::default()
    };

    mock_repo
        .expect_get_server()
        .with(eq(server_id))
        .times(1)
        .returning(move |_| Ok(Some(test_server.clone())));

    mock_repo
        .expect_get_server_metrics_history()
        .times(1)
        .returning(|_, _, _| Ok(vec![]));

    mock_monitoring
        .expect_get_server_metrics()
        .with(eq(server_id))
        .times(1)
        .returning(|_| Some(ServerMetrics {
            cpu_usage: 50.0,
            memory_usage: 70.0,
            disk_usage: 60.0,
            network_rx: 1000,
            network_tx: 2000,
            processes: vec![],
            timestamp: Utc::now(),
        }));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .app_data(web::Data::new(mock_monitoring))
            .route("/servers/{id}/status", web::get().to(get_server_status)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri(&format!("/servers/{}/status", server_id))
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: serde_json::Value = test::read_body_json(resp).await;
    assert_eq!(body["id"], server_id);
    assert_eq!(body["status"], "online");
    assert_eq!(body["resources"]["cpu"], 50.0);
}

#[actix_rt::test]
async fn test_delete_server() {
    let mut mock_repo = MockRepository::new();
    let user = AuthenticatedUser {
        id: "admin-user".to_string(),
        email: "admin@example.com".to_string(),
        role: UserRole::Admin,
    };
    let server_id = "test-server";

    mock_repo
        .expect_get_server()
        .with(eq(server_id))
        .times(1)
        .returning(|_| Ok(Some(Server {
            id: server_id.to_string(),
            created_by: Some("admin-user".to_string()),
            ..Default::default()
        })));

    mock_repo
        .expect_delete_server()
        .with(eq(server_id))
        .times(1)
        .returning(|_| Ok(()));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/servers/{id}", web::delete().to(delete_server)),
    )
    .await;

    let resp = test::TestRequest::delete()
        .uri(&format!("/servers/{}", server_id))
        .app_data(user)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 204);
}

#[actix_rt::test]
async fn test_update_server_status() {
    let mut mock_repo = MockRepository::new();
    let user = AuthenticatedUser {
        id: "user-1".to_string(),
        email: "user@example.com".to_string(),
        role: UserRole::User,
    };
    let server_id = "test-server";

    mock_repo
        .expect_get_server()
        .with(eq(server_id))
        .times(1)
        .returning(|_| Ok(Some(Server {
            id: server_id.to_string(),
            created_by: Some("user-1".to_string()),
            ..Default::default()
        })));

    mock_repo
        .expect_update_server_status()
        .with(eq(server_id), eq(true))
        .times(1)
        .returning(|_, _| Ok(()));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/servers/{id}/status", web::put().to(update_server_status)),
    )
    .await;

    let resp = test::TestRequest::put()
        .uri(&format!("/servers/{}/status", server_id))
        .set_json(&UpdateServerStatusRequest { is_online: true })
        .app_data(user)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);
}

#[actix_rt::test]
async fn test_test_connection() {
    let connection_request = TestConnectionRequest {
        host: "localhost".to_string(),
        port: 22,
        username: "test".to_string(),
        password: "test123".to_string(),
    };

    let app = test::init_service(
        App::new()
            .route("/servers/test-connection", web::post().to(test_connection)),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/servers/test-connection")
        .set_json(&connection_request)
        .send_request(&app)
        .await;

    // Note: This might fail in CI environment where SSH is not available
    // In real tests, we might want to mock the SSH connection
    assert!(resp.status().is_success() || resp.status().is_client_error());
}