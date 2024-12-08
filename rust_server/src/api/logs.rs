// src/api/logs.rs
use actix_web::{web, HttpResponse, Result};
use crate::{
    db::repository::Repository,
    models::logs::{CreateLogRequest, LogEntry, LogFilter, LogMetadata},
    error::AppError,
    api::response::ApiResponse,
};
use chrono::Utc;

pub async fn create_log(
    repo: web::Data<Repository>,
    request: web::Json<CreateLogRequest>,
) -> Result<HttpResponse, AppError> {
    let log = LogEntry {
        id: uuid::Uuid::new_v4().to_string(),
        level: request.level.clone(),
        message: request.message.clone(),
        component: request.component.clone(),
        server_id: request.server_id.clone(),
        timestamp: Utc::now(),
        metadata: LogMetadata {
            context: None,
            details: request.metadata.clone().map(|m| serde_json::to_value(m).unwrap_or_default()),
        },
        stack_trace: request.stack_trace.clone(),
        source_location: request.source_location.clone(),
        correlation_id: None,
    };

    match repo.create_log(log).await {
        Ok(created_log) => Ok(ApiResponse::success(created_log)),
        Err(e) => Ok(ApiResponse::<()>::error("database_error", &e.to_string())),
    }
}

pub async fn get_logs(
    repo: web::Data<Repository>,
    filter: web::Query<LogFilter>,
) -> Result<HttpResponse, AppError> {
    let logs = repo.get_logs(filter.into_inner()).await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    
    Ok(ApiResponse::success(logs))
}

pub async fn get_log(
    repo: web::Data<Repository>,
    log_id: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let log = repo.get_log(&log_id).await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    
    match log {
        Some(log) => Ok(ApiResponse::success(log)),
        None => Ok(ApiResponse::<()>::not_found("Log entry not found")),
    }
}

pub async fn delete_logs(
    repo: web::Data<Repository>,
    filter: web::Json<LogFilter>,
) -> Result<HttpResponse, AppError> {
    let deleted_count = repo.delete_logs(filter.into_inner()).await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    
    Ok(ApiResponse::success(deleted_count))
}