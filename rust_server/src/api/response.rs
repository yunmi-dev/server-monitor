// src/api/response.rs
use serde::{Serialize, Deserialize};
use actix_web::HttpResponse;

#[derive(Serialize, Deserialize)]
pub struct ApiResponse<T> {
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
        HttpResponse::BadRequest().json(ApiResponse::<T> {
            success: false,
            error: Some(error.to_string()),
            message: Some(message.to_string()),
            data: None,
        })
    }

    pub fn not_found(message: &str) -> HttpResponse {
        HttpResponse::NotFound().json(ApiResponse::<T> {
            success: false,
            error: Some("Resource not found".to_string()),
            message: Some(message.to_string()),
            data: None,
        })
    }

    pub fn unauthorized(message: &str) -> HttpResponse {
        HttpResponse::Unauthorized().json(ApiResponse::<T> {
            success: false,
            error: Some("Authentication failed".to_string()),
            message: Some(message.to_string()),
            data: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_response_serialization() {
        let response: ApiResponse<String> = ApiResponse {
            success: true,
            error: None,
            message: None,
            data: Some("test".to_string()),
        };
        
        let serialized = serde_json::to_string(&response).unwrap();
        let deserialized: ApiResponse<String> = serde_json::from_str(&serialized).unwrap();
        
        assert_eq!(deserialized.success, true);
        assert_eq!(deserialized.data.unwrap(), "test");
    }
}