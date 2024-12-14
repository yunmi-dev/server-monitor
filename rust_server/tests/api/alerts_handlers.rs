// tests/api/alerts_handlers.rs
use actix_web::{test, web, App};
use chrono::Utc;
use rust_server::{
    api::{alerts::{list_alerts, acknowledge_alert}, response::ApiResponse},
    db::models::{Alert, AlertSeverity},
};
use mockall::predicate::*;
use mockall::mock;

mock! {
    Repository {
        async fn get_unacknowledged_alerts(&self) -> Result<Vec<Alert>, anyhow::Error>;
        async fn acknowledge_alert(&self, alert_id: i64) -> Result<(), anyhow::Error>;
    }
}

#[actix_rt::test]
async fn test_list_alerts_success() {
    let mut mock_repo = MockRepository::new();
    let test_alerts = vec![
        Alert {
            id: 1,
            server_id: "test-server-1".to_string(),
            alert_type: "cpu_high".to_string(),
            severity: AlertSeverity::Critical,
            message: "CPU usage is too high".to_string(),
            created_at: Utc::now(),
            acknowledged_at: None,
            acknowledged_by: None,
        },
        Alert {
            id: 2,
            server_id: "test-server-2".to_string(),
            alert_type: "memory_warning".to_string(),
            severity: AlertSeverity::Warning,
            message: "Memory usage warning".to_string(),
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
            .service(web::resource("/alerts").route(web::get().to(list_alerts))),
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
    assert_eq!(alerts[0].alert_type, "cpu_high");
    assert_eq!(alerts[1].alert_type, "memory_warning");
}

#[actix_rt::test]
async fn test_acknowledge_alert_success() {
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
            .service(
                web::resource("/alerts/{id}/acknowledge")
                    .route(web::post().to(acknowledge_alert)),
            ),
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