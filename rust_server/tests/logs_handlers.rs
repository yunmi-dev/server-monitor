// tests/logs_handlers.rs
use actix_web::{test, web, App};
use chrono::Utc;
use uuid::Uuid;
use rust_server::{
    api::{logs::{create_log, get_logs, delete_logs}, response::ApiResponse},
    models::logs::{LogEntry, LogFilter, LogLevel, LogMetadata, CreateLogRequest},
};
use mockall::predicate::*;
use mockall::mock;
use serde_json::json;
use std::collections::HashMap;

mock! {
    Repository {
        async fn create_log(&self, log: LogEntry) -> Result<LogEntry, anyhow::Error>;
        async fn get_logs(&self, filter: LogFilter) -> Result<Vec<LogEntry>, anyhow::Error>;
        async fn get_log(&self, id: &str) -> Result<Option<LogEntry>, anyhow::Error>;
        async fn delete_logs(&self, filter: LogFilter) -> Result<i64, anyhow::Error>;
    }
}

#[actix_rt::test]
async fn test_create_log_success() {
    let mut mock_repo = MockRepository::new();
    let log_id = Uuid::new_v4().to_string();
    
    let request = CreateLogRequest {
        level: LogLevel::Info,
        message: "Test log message".to_string(),
        component: "test-component".to_string(),
        server_id: Some("test-server".to_string()),
        metadata: Some(HashMap::from([
            ("key".to_string(), json!("value"))
        ])),
        stack_trace: None,
        source_location: None,
    };

    mock_repo
        .expect_create_log()
        .times(1)
        .returning(move |log| Ok(LogEntry {
            id: log_id.clone(),
            level: log.level,
            message: log.message,
            component: log.component,
            server_id: log.server_id,
            timestamp: log.timestamp,
            metadata: log.metadata,
            stack_trace: log.stack_trace,
            source_location: log.source_location,
            correlation_id: log.correlation_id,
        }));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .service(web::resource("/logs").route(web::post().to(create_log))),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/logs")
        .set_json(&request)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<LogEntry> = test::read_body_json(resp).await;
    assert!(body.success);
    let created_log = body.data.unwrap();
    assert!(created_log.level.to_string() == "info");
    assert_eq!(created_log.message, "Test log message");
    assert_eq!(created_log.component, "test-component");
}

#[actix_rt::test]
async fn test_get_logs_with_filter() {
    let mut mock_repo = MockRepository::new();
    let _test_logs = vec![
        LogEntry {
            id: Uuid::new_v4().to_string(),
            level: LogLevel::Info,
            message: "Test log 1".to_string(),
            component: "test-component".to_string(),
            server_id: Some("test-server".to_string()),
            timestamp: Utc::now(),
            metadata: LogMetadata::default(),
            stack_trace: None,
            source_location: None,
            correlation_id: None,
        },
        LogEntry {
            id: Uuid::new_v4().to_string(),
            level: LogLevel::Warning,
            message: "Test log 2".to_string(),
            component: "test-component".to_string(),
            server_id: Some("test-server".to_string()),
            timestamp: Utc::now(),
            metadata: LogMetadata::default(),
            stack_trace: None,
            source_location: None,
            correlation_id: None,
        },
    ];

    mock_repo
        .expect_get_logs()
        .times(1)
        .returning(move |_| {
            Ok(vec![
                LogEntry {
                    id: Uuid::new_v4().to_string(),
                    level: LogLevel::Info,
                    message: "Test log 1".to_string(),
                    component: "test-component".to_string(),
                    server_id: Some("test-server".to_string()),
                    timestamp: Utc::now(),
                    metadata: LogMetadata::default(),
                    stack_trace: None,
                    source_location: None,
                    correlation_id: None,
                },
                LogEntry {
                    id: Uuid::new_v4().to_string(),
                    level: LogLevel::Warning,
                    message: "Test log 2".to_string(),
                    component: "test-component".to_string(),
                    server_id: Some("test-server".to_string()),
                    timestamp: Utc::now(),
                    metadata: LogMetadata::default(),
                    stack_trace: None,
                    source_location: None,
                    correlation_id: None,
                },
            ])
        });

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .service(web::resource("/logs").route(web::get().to(get_logs))),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/logs?server_id=test-server")
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<Vec<LogEntry>> = test::read_body_json(resp).await;
    assert!(body.success);
    assert_eq!(body.data.unwrap().len(), 2);
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
            .service(web::resource("/logs").route(web::delete().to(delete_logs))),
    )
    .await;

    let filter = LogFilter {
        server_id: Some("test-server".to_string()),
        levels: Some(vec![LogLevel::Warning]),
        from: None,
        to: None,
        component: None,
        search: None,
        limit: None,
        offset: None,
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