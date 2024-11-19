// src/api/alerts.rs
use actix_web::{web, HttpResponse};
use crate::db::repository::Repository;
use crate::api::response::ApiResponse;
use crate::error::AppError;

pub async fn list_alerts(
    repo: web::Data<Repository>
) -> Result<HttpResponse, AppError> {
    // Method 1: Use map_err for explicit conversion
    let alerts = repo.get_unacknowledged_alerts()
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    Ok(ApiResponse::success(alerts))
}

pub async fn acknowledge_alert(
    repo: web::Data<Repository>,
    alert_id: web::Path<i64>,
) -> Result<HttpResponse, AppError> {
    repo.acknowledge_alert(*alert_id)
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    Ok(ApiResponse::success(()))
}