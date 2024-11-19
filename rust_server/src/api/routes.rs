// src/api/routes.rs
use actix_web::web;
use super::{servers, health, alerts};

pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/v1")
            // Health check
            .route("/health", web::get().to(health::health_check))
            // Server management
            .service(
                web::scope("/servers")
                    .route("", web::post().to(servers::create_server))
                    .route("", web::get().to(servers::get_servers))
                    .route("/{id}", web::get().to(servers::get_server))
                    .route("/{id}/status", web::put().to(servers::update_server_status))
                    .route("/{id}/metrics", web::get().to(servers::get_server_metrics))
            )
            // Alerts
            .service(
                web::scope("/alerts")
                    .route("", web::get().to(alerts::list_alerts))
                    .route("/{id}/acknowledge", web::post().to(alerts::acknowledge_alert))
            )
    );
}