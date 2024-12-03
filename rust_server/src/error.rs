// src/error.rs
use actix_web::{HttpResponse, ResponseError, http::StatusCode};
use thiserror::Error;
use serde_json::json;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("Internal error: {0}")]
    InternalError(String),
    
    #[error("Authentication error: {0}")]
    AuthError(String),

    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Internal server error: {0}")]
    Internal(String),

    #[error("Bad request: {0}")]
    BadRequest(String),
    
    #[error("External service error: {0}")]
    ExternalService(String),
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, error_type) = match self {
            AppError::InternalError(_) => 
                (StatusCode::INTERNAL_SERVER_ERROR, "internal_error"),
            AppError::DatabaseError(_) => 
                (StatusCode::INTERNAL_SERVER_ERROR, "database_error"),
            AppError::AuthError(_) => 
                (StatusCode::UNAUTHORIZED, "authentication_error"),
            AppError::ValidationError(_) => 
                (StatusCode::BAD_REQUEST, "validation_error"),
            AppError::NotFound(_) => 
                (StatusCode::NOT_FOUND, "not_found"),
            AppError::Internal(_) => 
                (StatusCode::INTERNAL_SERVER_ERROR, "internal_error"),
            AppError::BadRequest(_) => 
                (StatusCode::BAD_REQUEST, "bad_request"),
            AppError::ExternalService(_) => 
                (StatusCode::BAD_GATEWAY, "external_service_error"),
        };

        HttpResponse::build(status).json(json!({
            "success": false,
            "error": error_type,
            "message": self.to_string(),
            "data": null
        }))
    }

    fn status_code(&self) -> StatusCode {
        match self {
            AppError::InternalError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::DatabaseError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::AuthError(_) => StatusCode::UNAUTHORIZED,
            AppError::ValidationError(_) => StatusCode::BAD_REQUEST,
            AppError::NotFound(_) => StatusCode::NOT_FOUND,
            AppError::Internal(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::BadRequest(_) => StatusCode::BAD_REQUEST,
            AppError::ExternalService(_) => StatusCode::BAD_GATEWAY,
        }
    }
}

impl From<anyhow::Error> for AppError {
    fn from(err: anyhow::Error) -> Self {
        AppError::Internal(err.to_string())
    }
}