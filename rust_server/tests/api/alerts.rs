// tests/api/alerts.rs
use actix_web::{test, web, App};
use chrono::Utc;
use rust_server::{
    api::response::ApiResponse,
    api::alerts::*,
    db::models::*,
};
use mockall::predicate::*;
use mockall::mock;

mock! {
    Repository {
        async fn get_unacknowledged_alerts(&self) -> anyhow::Result<Vec<Alert>>;
        async fn acknowledge_alert(&self, alert_id: i64) -> anyhow::Result<()>;
    }
}

#[actix_rt::test]
async fn test_list_alerts() {
    let mut mock_repo = MockRepository::new();
    let test_alerts = vec![
        Alert {
            id: 1,
            server_id: "test-server-1".to_string(),
            alert_type: "high_cpu_usage".to_string(),
            severity: AlertSeverity::Critical,
            message: "CPU usage exceeded 90%".to_string(),
            created_at: Utc::now(),
            acknowledged_at: None,
            acknowledged_by: None,
        },
        Alert {
            id: 2,
            server_id: "test-server-2".to_string(),
            alert_type: "low_disk_space".to_string(),
            severity: AlertSeverity::Warning,
            message: "Disk space below 10%".to_string(),
            created_at: Utc::now(),
            acknowledged_at: None,
            acknowledged_by: None,
        },
    ];

    mock_repo
        .expect_get_unacknowledged_alerts()
        .times(1)
        .returning(move || Ok(test_alerts.clone()));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/alerts", web::get().to(list_alerts)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/alerts")
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<Vec<Alert>> = test::read_body_json(resp).await;
    assert!(body.success);
    let alerts = body.data.unwrap();
    assert_eq!(alerts.len(), 2);
    assert_eq!(alerts[0].severity, AlertSeverity::Critical);
    assert_eq!(alerts[1].severity, AlertSeverity::Warning);
}

#[actix_rt::test]
async fn test_acknowledge_alert() {
    let mut mock_repo = MockRepository::new();
    let alert_id = 1;

    mock_repo
        .expect_acknowledge_alert()
        .with(eq(alert_id))
        .times(1)
        .returning(|_| Ok(()));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/alerts/{id}/acknowledge", web::post().to(acknowledge_alert)),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri(&format!("/alerts/{}/acknowledge", alert_id))
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<()> = test::read_body_json(resp).await;
    assert!(body.success);
}

#[actix_rt::test]
async fn test_list_alerts_error_handling() {
    let mut mock_repo = MockRepository::new();

    mock_repo
        .expect_get_unacknowledged_alerts()
        .times(1)
        .returning(|| Err(anyhow::Error::msg("Database error")));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/alerts", web::get().to(list_alerts)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/alerts")
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 500);

    let body: ApiResponse<Vec<Alert>> = test::read_body_json(resp).await;
    assert!(!body.success);
    assert!(body.error.is_some());
}

#[actix_rt::test]
async fn test_acknowledge_alert_error_handling() {
    let mut mock_repo = MockRepository::new();
    let alert_id = 1;

    mock_repo
        .expect_acknowledge_alert()
        .with(eq(alert_id))
        .times(1)
        .returning(|_| Err(anyhow::Error::msg("Database error")));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/alerts/{id}/acknowledge", web::post().to(acknowledge_alert)),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri(&format!("/alerts/{}/acknowledge", alert_id))
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 500);

    let body: ApiResponse<()> = test::read_body_json(resp).await;
    assert!(!body.success);
    assert!(body.error.is_some());
}

#[actix_rt::test]
async fn test_list_alerts_empty() {
    let mut mock_repo = MockRepository::new();

    mock_repo
        .expect_get_unacknowledged_alerts()
        .times(1)
        .returning(|| Ok(vec![]));

    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .route("/alerts", web::get().to(list_alerts)),
    )
    .await;

    let resp = test::TestRequest::get()
        .uri("/alerts")
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: ApiResponse<Vec<Alert>> = test::read_body_json(resp).await;
    assert!(body.success);
    assert_eq!(body.data.unwrap().len(), 0);
}