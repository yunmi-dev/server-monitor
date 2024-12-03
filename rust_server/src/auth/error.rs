// src/error.rs
use thiserror::Error;
use actix_web::{HttpResponse, ResponseError};
use serde_json::json;

#[allow(dead_code)]
#[derive(Debug, Error)]
pub enum AppError {
    #[error("Authentication error: {0}")]
    AuthError(String),

    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Internal server error: {0}")]
    InternalError(String),

    #[error("Bad request: {0}")]
    BadRequest(String),

    #[error("External service error: {0}")]
    ExternalService(String),
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        match self {
            AppError::AuthError(msg) => {
                HttpResponse::Unauthorized().json(json!({
                    "error": "unauthorized",
                    "message": msg
                }))
            }
            AppError::DatabaseError(_) => {
                HttpResponse::InternalServerError().json(json!({
                    "error": "database_error",
                    "message": self.to_string()
                }))
            }
            AppError::ValidationError(msg) => {
                HttpResponse::BadRequest().json(json!({
                    "error": "validation_error",
                    "message": msg
                }))
            }
            AppError::NotFound(msg) => {
                HttpResponse::NotFound().json(json!({
                    "error": "not_found",
                    "message": msg
                }))
            }
            AppError::InternalError(msg) => {
                HttpResponse::InternalServerError().json(json!({
                    "error": "internal_server_error",
                    "message": msg
                }))
            }
            AppError::BadRequest(msg) => {
                HttpResponse::BadRequest().json(json!({
                    "error": "bad_request",
                    "message": msg
                }))
            }
            AppError::ExternalService(msg) => {
                HttpResponse::InternalServerError().json(json!({
                    "error": "external_service_error",
                    "message": msg
                }))
            }
        }
    }
}

// auth 모듈에서 사용할 에러 타입 별칭
pub type AuthError = AppError;