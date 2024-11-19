// src/error.rs
use actix_web::{HttpResponse, ResponseError, http::StatusCode}; // Added StatusCode import
use thiserror::Error;
use serde_json::json;
use sqlx::Error as SqlxError;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Database error: {0}")]
    DatabaseError(#[from] SqlxError),

    #[error("Authentication error: {0}")]
    AuthError(String),

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Internal server error: {0}")]
    InternalError(String),
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, error_type) = match self {
            AppError::DatabaseError(_) => 
                (StatusCode::INTERNAL_SERVER_ERROR, "Database error occurred"),
            AppError::AuthError(_) => 
                (StatusCode::UNAUTHORIZED, "Authentication failed"),
            AppError::ValidationError(_) => 
                (StatusCode::BAD_REQUEST, "Validation failed"), 
            AppError::NotFound(_) => 
                (StatusCode::NOT_FOUND, "Resource not found"),
            AppError::InternalError(_) => 
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error"),
        };

        HttpResponse::build(status).json(json!({
            "success": false,
            "error": error_type,
            "message": self.to_string(),
            "data": null
        }))
    }
}

impl From<anyhow::Error> for AppError {
    fn from(err: anyhow::Error) -> Self {
        AppError::InternalError(err.to_string())
    }
}