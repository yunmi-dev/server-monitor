// src/api/mod.rs
mod alerts;
pub mod handlers;
pub mod health;
mod response;
mod routes;
mod servers;
mod logs;

pub use routes::configure_routes;