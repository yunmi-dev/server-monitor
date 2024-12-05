// src/api/mod.rs
pub mod alerts;
pub mod handlers;
pub mod health;
pub mod response;
pub mod routes;
pub mod servers;
pub mod logs;

pub use routes::configure_routes;