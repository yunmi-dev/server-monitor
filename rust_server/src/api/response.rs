// src/api/response.rs
use serde::{Serialize, Deserialize};
use actix_web::HttpResponse;

#[derive(Serialize, Deserialize)]
#[serde(bound = "T: Serialize + for<'a> Deserialize<'a>")]
pub struct ApiResponse<T>
where
    T: Serialize,
{
    pub success: bool,
    pub error: Option<String>,
    pub message: Option<String>,
    pub data: Option<T>,
}

impl<T> ApiResponse<T>
where
    T: Serialize,
{
    pub fn success(data: T) -> HttpResponse {
        HttpResponse::Ok().json(Self {
            success: true,
            error: None,
            message: None,
            data: Some(data),
        })
    }

    pub fn error(error: &str, message: &str) -> HttpResponse {
        HttpResponse::BadRequest().json(Self {
            success: false,
            error: Some(error.to_string()),
            message: Some(message.to_string()),
            data: None,
        })
    }

    pub fn not_found(message: &str) -> HttpResponse {
        HttpResponse::NotFound().json(Self {
            success: false,
            error: Some("Resource not found".to_string()),
            message: Some(message.to_string()),
            data: None,
        })
    }

    pub fn unauthorized(message: &str) -> HttpResponse {
        HttpResponse::Unauthorized().json(Self {
            success: false,
            error: Some("Authentication failed".to_string()),
            message: Some(message.to_string()),
            data: None,
        })
    }
}

// 테스트용 응답 구조체
#[cfg(test)]
#[derive(Serialize, Deserialize)]
pub struct TestResponse {
    pub success: bool,
    pub error: Option<String>,
    pub message: Option<String>,
    pub data: Option<serde_json::Value>,
}