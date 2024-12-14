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