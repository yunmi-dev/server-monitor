// src/api/mod.rs
mod alerts;
mod handlers;
mod health;
mod response;
mod routes;
mod servers;
mod logs;

pub use routes::configure_routes;
pub use handlers::*;
