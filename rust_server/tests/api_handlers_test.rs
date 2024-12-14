// tests/api_handlers_test.rs
use actix_web::{test, web, App};
use mockall::predicate::*;
use mockall::mock;
use rust_server::{
    api::{handlers::*, response::ApiResponse},
    models::metrics::{ServerMetrics, ProcessMetrics},
};

mod common;
use common::{create_test_user, create_test_config};


// MonitoringService 모의 객체 생성
mock! {
    MonitoringService {
        async fn get_current_metrics(&self) -> Option<ServerMetrics>;
        async fn get_server_metrics(&self, server_id: &str) -> Option<ServerMetrics>;
        async fn get_server_processes(&self, server_id: &str) -> Option<Vec<ProcessMetrics>>;
    }
}

#[actix_rt::test]
async fn test_get_metrics_success() {
    // 테스트용 메트릭 데이터
    let test_metrics = ServerMetrics::new(
        50.0,
        70.0,
        60.0,
        1000,
        2000,
        vec![
            ProcessMetrics::new(1, "test-process".to_string(), 10.0, 1024),
        ],
    );

    // MonitoringService 모의 객체 설정
    let mut mock_monitoring = MockMonitoringService::new();
    mock_monitoring
        .expect_get_current_metrics()
        .times(1)
        .returning(move || Some(test_metrics.clone()));

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_monitoring))
            .route("/metrics", web::get().to(get_metrics)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/metrics")
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let bytes = test::read_body(resp).await;
    let body: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    
    assert_eq!(body["success"], serde_json::json!(true));
    let metrics = body["data"].as_object().unwrap();
    assert_eq!(metrics["cpu_usage"], serde_json::json!(50.0));
}

#[actix_rt::test]
async fn test_get_metrics_no_data() {
    // MonitoringService 모의 객체 설정
    let mut mock_monitoring = MockMonitoringService::new();
    mock_monitoring
        .expect_get_current_metrics()
        .times(1)
        .returning(|| None);

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_monitoring))
            .route("/metrics", web::get().to(get_metrics)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/metrics")
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<ServerMetrics> = test::read_body_json(resp).await;
    assert!(!body.success);
    assert_eq!(body.error.unwrap(), "Metrics Error");
}

#[actix_rt::test]
async fn test_get_server_metrics_success() {
    let server_id = "test-server-123";
    
    // 테스트용 메트릭 데이터
    let test_metrics = ServerMetrics::new(
        50.0,
        70.0,
        60.0,
        1000,
        2000,
        vec![
            ProcessMetrics::new(1, "test-process".to_string(), 10.0, 1024),
        ],
    );

    // MonitoringService 모의 객체 설정
    let mut mock_monitoring = MockMonitoringService::new();
    mock_monitoring
        .expect_get_server_metrics()
        .with(eq(server_id))
        .times(1)
        .returning(move |_| Some(test_metrics.clone()));

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_monitoring))
            .route("/servers/{id}/metrics", web::get().to(get_server_metrics)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri(&format!("/servers/{}/metrics", server_id))
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<ServerMetrics> = test::read_body_json(resp).await;
    assert!(body.success);
    let metrics = body.data.unwrap();
    assert_eq!(metrics.cpu_usage, 50.0);
    assert_eq!(metrics.processes.len(), 1);
}

#[actix_rt::test]
async fn test_get_server_processes_success() {
    let server_id = "test-server-123";
    
    // 테스트용 프로세스 데이터
    let test_processes = vec![
        ProcessMetrics::new(1, "test-process".to_string(), 10.0, 1024),
        ProcessMetrics::new(2, "another-process".to_string(), 20.0, 2048),
    ];

    // MonitoringService 모의 객체 설정
    let mut mock_monitoring = MockMonitoringService::new();
    mock_monitoring
        .expect_get_server_processes()
        .with(eq(server_id))
        .times(1)
        .returning(move |_| Some(test_processes.clone()));

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_monitoring))
            .route("/servers/{id}/processes", web::get().to(get_server_processes)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri(&format!("/servers/{}/processes", server_id))
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<Vec<ProcessMetrics>> = test::read_body_json(resp).await;
    assert!(body.success);
    let processes = body.data.unwrap();
    assert_eq!(processes.len(), 2);
    assert_eq!(processes[0].pid, 1);
    assert_eq!(processes[0].memory_usage, 1024);
}

#[actix_rt::test]
async fn test_get_server_metrics_not_found() {
    let server_id = "nonexistent-server";

    // MonitoringService 모의 객체 설정
    let mut mock_monitoring = MockMonitoringService::new();
    mock_monitoring
        .expect_get_server_metrics()
        .with(eq(server_id))
        .times(1)
        .returning(|_| None);

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_monitoring))
            .route("/servers/{id}/metrics", web::get().to(get_server_metrics)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri(&format!("/servers/{}/metrics", server_id))
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<ServerMetrics> = test::read_body_json(resp).await;
    assert!(!body.success);
    assert!(body.error.is_some());
    assert!(body.message.unwrap().contains("No metrics found for server"));
}