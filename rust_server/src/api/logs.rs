// src/api/logs.rs
use actix_web::{web, HttpResponse, Result};
use crate::{
    db::repository::Repository,
    models::logs::{LogEntry, LogFilter, LogLevel, LogMetadata},
    error::AppError,
    api::response::ApiResponse,
};
use serde::Deserialize;
use std::collections::HashMap;

#[derive(Deserialize)]
pub struct CreateLogRequest {
    pub level: LogLevel,
    pub message: String,
    pub component: String,
    pub server_id: Option<String>,
    #[serde(default)]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
    pub stack_trace: Option<String>,
    pub source_location: Option<String>,
}

pub async fn create_log(
    repo: web::Data<Repository>,
    log: web::Json<CreateLogRequest>,
) -> Result<HttpResponse, AppError> {
    let log_entry = LogEntry {
        id: uuid::Uuid::new_v4().to_string(),
        level: log.level.clone(),
        message: log.message.clone(),
        component: log.component.clone(),
        server_id: log.server_id.clone(),
        timestamp: chrono::Utc::now(),
        metadata: LogMetadata(log.metadata.clone()), // LogMetadata로 래핑
        stack_trace: log.stack_trace.clone(),
        source_location: log.source_location.clone(),
        correlation_id: None,
        message_tsv: None,  // message_tsv 필드 추가
    };

    let result = repo.create_log(log_entry).await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    
    Ok(ApiResponse::success(result))
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