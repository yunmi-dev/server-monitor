// src/websocket/mod.rs
pub mod handlers;
pub use handlers::WebSocketConnection;

use actix_web::{web, Error, HttpRequest, HttpResponse};
use actix_web_actors::ws;
use crate::monitoring::MonitoringService;
use crate::db::repository::Repository;
use std::sync::Arc;

pub async fn ws_index(
    req: HttpRequest,
    stream: web::Payload,
    monitoring_service: web::Data<MonitoringService>,
    repository: web::Data<Arc<Repository>>,
) -> Result<HttpResponse, Error> {
    ws::start(
        WebSocketConnection::new(
            monitoring_service.get_ref().clone(),
            repository.get_ref().clone(),
        ),
        &req,
        stream,
    )
}

// pub fn configure_routes(cfg: &mut web::ServiceConfig) {
//     cfg.service(
//         web::scope("/api/v1")
//             .route("/ws", web::get().to(
//                 |req: actix_web::HttpRequest,
//                  stream: web::Payload,
//                  monitoring_service: web::Data<MonitoringService>,
//                  repository: web::Data<Repository>| async move {
//                     ws::start(
//                         WebSocketConnection::new(
//                             monitoring_service.get_ref().clone(),
//                             Arc::new(repository.get_ref().clone())
//                         ),
//                         &req,
//                         stream
//                     )
//                 }
//             ))
//     );
// }