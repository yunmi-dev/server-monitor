use actix_web::{web, HttpResponse, Result};
use crate::monitoring::MonitoringService;
use crate::error::AppError;
use crate::api::response::ApiResponse;

pub async fn get_metrics(
    monitoring: web::Data<MonitoringService>,
) -> Result<HttpResponse, AppError> {
    if let Some(metrics) = monitoring.get_current_metrics().await {
        Ok(ApiResponse::success(metrics))
    } else {
        Ok(ApiResponse::<()>::error("Metrics Error", "No metrics available"))
    }
}

pub async fn get_server_metrics(
    monitoring: web::Data<MonitoringService>,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let server_id = path.into_inner();
    if let Some(metrics) = monitoring.get_server_metrics(&server_id).await {
        Ok(ApiResponse::success(metrics))
    } else {
        Ok(ApiResponse::<()>::error(
            "Metrics Error",
            &format!("No metrics found for server {}", server_id)
        ))
    }
}

pub async fn get_server_processes(
    monitoring: web::Data<MonitoringService>,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let server_id = path.into_inner();
    if let Some(processes) = monitoring.get_server_processes(&server_id).await {
        Ok(ApiResponse::success(processes))
    } else {
        Ok(ApiResponse::<()>::error(
            "Process Error",
            &format!("No processes found for server {}", server_id)
        ))
    }
}
