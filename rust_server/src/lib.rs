// src/lib.rs

pub mod api;
pub mod auth;
pub mod config;
pub mod db;
pub mod models;
pub mod error;
pub mod monitoring;
pub mod websocket;
pub mod utils;

pub use error::AppError;

// API 응답 타입 지정
//pub type ApiResponse<T> = api::response::ApiResponse<T>;