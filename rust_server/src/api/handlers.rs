// server/src/api/handlers.rs

use actix_web::{web, HttpResponse, Result};
use crate::monitoring::MonitoringService;
<<<<<<< HEAD
//use crate::models::metrics::ServerMetrics;
=======
use crate::models::metrics::ServerMetrics;
>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d
use crate::error::AppError;
use crate::api::response::ApiResponse;

pub async fn get_metrics(
    monitoring: web::Data<MonitoringService>,
) -> Result<HttpResponse, AppError> {
    if let Some(metrics) = monitoring.get_current_metrics().await {
        Ok(ApiResponse::success(metrics))
    } else {
<<<<<<< HEAD
        Ok(ApiResponse::<()>::error("No metrics available"))
    }
}

=======
        Ok(ApiResponse::error("No metrics available"))
    }
}

pub async fn get_servers(
    repository: web::Data<crate::db::Repository>,
) -> Result<HttpResponse, AppError> {
    let servers = repository.list_servers().await?;
    Ok(ApiResponse::success(servers))
}

>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d
pub async fn get_server_metrics(
    monitoring: web::Data<MonitoringService>,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let server_id = path.into_inner();
    if let Some(metrics) = monitoring.get_server_metrics(&server_id).await {
        Ok(ApiResponse::success(metrics))
    } else {
<<<<<<< HEAD
        Ok(ApiResponse::<()>::error(&format!("No metrics found for server {}", server_id)))
=======
        Ok(ApiResponse::error(&format!("No metrics found for server {}", server_id)))
>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d
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
<<<<<<< HEAD
        Ok(ApiResponse::<()>::error(&format!("No processes found for server {}", server_id)))
=======
        Ok(ApiResponse::error(&format!("No processes found for server {}", server_id)))
>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d
    }
}