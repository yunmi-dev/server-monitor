// src/websocket/mod.rs
pub mod handlers;
pub use handlers::WebSocketConnection;

use actix_web::{web, HttpRequest, HttpResponse};
use actix_web_actors::ws;
use crate::monitoring::MonitoringService;
use actix_web::http::header::{self, HeaderValue};

// pub async fn ws_index(
//     req: HttpRequest,
//     stream: web::Payload,
//     monitoring_service: web::Data<MonitoringService>,
// ) -> Result<HttpResponse, actix_web::Error> {
//     ws::start(
//         WebSocketConnection::new(monitoring_service.get_ref().clone()),
//         &req,
//         stream,
//     )
// }
pub async fn ws_index(
    req: HttpRequest,
    stream: web::Payload,
    monitoring_service: web::Data<MonitoringService>,
) -> Result<HttpResponse, actix_web::Error> {
    println!("WebSocket connection headers: {:?}", req.headers());
    
    // 먼저 websocket upgrade 확인
    if !req.headers().contains_key("sec-websocket-key") {
        return Ok(HttpResponse::BadRequest()
            .body("WebSocket upgrade required"));
    }

    let mut res = ws::start(
        WebSocketConnection::new(monitoring_service.get_ref().clone()),
        &req,
        stream,
    )?;
    
    // 응답 헤더에 upgrade와 connection 추가
    res.headers_mut()
        .insert(header::UPGRADE, HeaderValue::from_static("websocket"));
    res.headers_mut()
        .insert(header::CONNECTION, HeaderValue::from_static("upgrade"));
    
    println!("WebSocket connection established");
    Ok(res)
}