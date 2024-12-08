// src/websocket/mod.rs
pub mod handlers;
pub use handlers::WebSocketConnection;

use actix_web::{web, HttpRequest, HttpResponse};
use actix_web_actors::ws;
use crate::monitoring::MonitoringService;

pub async fn ws_index(
    req: HttpRequest,
    stream: web::Payload,
    monitoring_service: web::Data<MonitoringService>,
) -> Result<HttpResponse, actix_web::Error> {
    println!("WebSocket connection request received");
    
    if !req.headers().contains_key("sec-websocket-key") {
        return Ok(HttpResponse::BadRequest().body("WebSocket upgrade required"));
    }

    let resp = ws::start(
        WebSocketConnection::new(monitoring_service.as_ref().clone()),
        &req,
        stream,
    )?;

    println!("WebSocket connection established");
    Ok(resp)
}