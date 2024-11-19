// src/api/response.rs
use serde::Serialize;
use actix_web::HttpResponse;


// #[derive(Serialize)]
// pub struct ApiResponse<T> 
// where
//     T: Serialize,
// {
//     pub success: bool,
//     pub data: Option<T>,
//     pub error: Option<String>,
// }

// impl<T: Serialize> ApiResponse<T> {
//     pub fn success(data: T) -> HttpResponse {
//         HttpResponse::Ok().json(Self {
//             success: true,
//             data: Some(data),
//             error: None,
//         })
//     }

//     pub fn error(err: &str) -> HttpResponse {
//         HttpResponse::BadRequest().json(Self {
//             success: false,
//             data: None,
//             error: Some(err.to_string()),
//         })
//     }
// }

#[derive(Serialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>
}

// 성공 응답을 위한 구현
impl<T: Serialize> ApiResponse<T> {
    pub fn success(data: T) -> HttpResponse {
        HttpResponse::Ok().json(ApiResponse {
            success: true,
            data: Some(data),
            error: None
        })
    }
}

// 에러 응답을 위한 구현
impl ApiResponse<()> {
    pub fn error(message: &str) -> HttpResponse {
        HttpResponse::Ok().json(ApiResponse::<()> {
            success: false,
            data: None,
            error: Some(message.to_string())
        })
    }
}

// 필요한 경우 커스텀 에러 타입을 위한 구현
impl<E: Serialize> ApiResponse<E> {
    pub fn error_with_data(message: &str, error_data: E) -> HttpResponse {
        HttpResponse::Ok().json(ApiResponse {
            success: false,
            data: Some(error_data),
            error: Some(message.to_string())
        })
    }
}