// src/api/routes.rs
use actix_web::web;
use crate::auth::handlers::*;
use crate::api::health::health_check;
use crate::api::servers::{
    create_server, delete_server, get_server, get_servers,
    update_server_status, get_server_metrics, test_connection, get_server_status,
};
use crate::api::logs::{create_log, get_logs, get_log, delete_logs};
use crate::api::alerts::{list_alerts, acknowledge_alert};
use crate::websocket::ws_index;
use crate::auth::middleware::AuthMiddleware; 



pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.app_data(web::JsonConfig::default().limit(4096))
       .service(
        web::scope("/api/v1")
            .route("/ws", web::get().to(ws_index))
            .service(
                web::scope("/auth")
                    .service(login)
                    .service(register)
                    .service(social_login)
            )
            .route("/health", web::get().to(health_check))
            .service(
                web::scope("/servers")
                    .wrap(AuthMiddleware)  // 인증 미들웨어 적용
                    .route("/test-connection", web::post().to(test_connection))
                    .route("", web::post().to(create_server))
                    .route("", web::get().to(get_servers))
                    .route("/{server_id}", web::get().to(get_server))
                    .route("/{server_id}/status", web::get().to(get_server_status))
                    .route("/{server_id}/status", web::put().to(update_server_status))
                    .route("/{server_id}", web::delete().to(delete_server))
                    .route("/{server_id}/metrics", web::get().to(get_server_metrics))
            )
            .service(
                web::scope("/logs")
                    .route("", web::post().to(create_log))
                    .route("", web::get().to(get_logs))
                    .route("/{log_id}", web::get().to(get_log))
                    .route("", web::delete().to(delete_logs))
            )
            .service(
                web::scope("/alerts")
                    .route("", web::get().to(list_alerts))
                    .route("/{alert_id}/acknowledge", web::post().to(acknowledge_alert))
            )
    );
}