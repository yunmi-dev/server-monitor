// src/api/routes.rs
use actix_web::web;
use crate::auth::handlers::{register, social_login};
use crate::api::health::health_check;
use crate::websocket::WebSocketConnection; 
use crate::monitoring::MonitoringService;
use crate::db::repository::Repository; 
use std::sync::Arc; 
use actix_web_actors::ws;
use crate::api::servers::{
    create_server,
    delete_server,
    get_server,
    get_servers,
    update_server_status,
    get_server_metrics,
    test_connection
};
use crate::api::logs::{
    create_log,
    get_logs,
    get_log,
    delete_logs
};
use crate::api::alerts::{
    list_alerts,
    acknowledge_alert
};

pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/v1")
            // Health check route
            .route("/health", web::get().to(health_check))
            
            // Authentication routes
            .service(register)
            .service(social_login)
            
            // Server management routes
            .service(
                web::scope("/servers")
                    .route("", web::post().to(create_server))
                    .route("", web::get().to(get_servers))
                    .route("/{server_id}", web::get().to(get_server))
                    .route("/{server_id}/status", web::put().to(update_server_status))
                    .route("/{server_id}", web::delete().to(delete_server))
                    .route("/{server_id}/metrics", web::get().to(get_server_metrics))
                    .route("/test-connection", web::post().to(test_connection))
            )
            
            // Logs routes
            .service(
                web::scope("/logs")
                    .route("", web::post().to(create_log))
                    .route("", web::get().to(get_logs))
                    .route("/{log_id}", web::get().to(get_log))
                    .route("", web::delete().to(delete_logs))
            )
            
            // Alerts routes
            .service(
                web::scope("/alerts")
                    .route("", web::get().to(list_alerts))
                    .route("/{alert_id}/acknowledge", web::post().to(acknowledge_alert))
            )
 
            // WebSocket route
            .route("/ws", web::get().to(
                |req: actix_web::HttpRequest,
                 stream: web::Payload,
                 monitoring_service: web::Data<MonitoringService>,
                 repository: web::Data<Repository>| async move {
                    ws::start(
                        WebSocketConnection::new(
                            monitoring_service.get_ref().clone(),
                            Arc::new(repository.get_ref().clone())
                        ),
                        &req,
                        stream
                    )
                }
            ))

    );
}