// src/websocket/mod.rs
mod handlers;

use actix_web::{web, Error, HttpRequest, HttpResponse};
use actix_web_actors::ws;
use crate::monitoring::MonitoringService;
use crate::db::repository::Repository;
use std::sync::Arc;

pub use handlers::WebSocketConnection;

pub async fn ws_index(
    req: HttpRequest,
    stream: web::Payload,
    monitoring_service: web::Data<MonitoringService>,
    repository: web::Data<Arc<Repository>>,  // Arc<Repository>로 수정
) -> Result<HttpResponse, Error> {
    ws::start(
        WebSocketConnection::new(
            monitoring_service.get_ref().clone(),
            repository.get_ref().clone(),  // 이미 Arc이므로 그대로 clone
        ),
        &req,
        stream,
    )
}

pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(web::resource("/ws").route(web::get().to(ws_index)));
}