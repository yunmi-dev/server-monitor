// src/websocket/handlers.rs
use actix::{
    Actor, ActorContext, AsyncContext, Handler, Message, StreamHandler, 
    SpawnHandle, ActorFutureExt, WrapFuture,
};
use actix_web_actors::ws;
use serde_json::json;
use std::time::{Duration, Instant};
use std::sync::{Arc, Mutex};
use std::collections::HashMap;
use crate::monitoring::MonitoringService;
use crate::db::models::MetricsSnapshot;

const HEARTBEAT_INTERVAL: Duration = Duration::from_secs(5);
const CLIENT_TIMEOUT: Duration = Duration::from_secs(10);

pub struct WebSocketConnection {
    last_heartbeat: Instant,
    monitoring_service: MonitoringService,
    subscription_handles: Arc<Mutex<HashMap<String, SpawnHandle>>>,
    server_id: Option<String>,
    //repository: Arc<Repository>,
}

impl WebSocketConnection {
    pub fn new(monitoring_service: MonitoringService) -> Self {
        Self {
            last_heartbeat: Instant::now(),
            monitoring_service,
            subscription_handles: Arc::new(Mutex::new(HashMap::new())),
            server_id: None,
        }
    }

    fn schedule_heartbeat(&self, ctx: &mut ws::WebsocketContext<Self>) {
        ctx.run_interval(HEARTBEAT_INTERVAL, |act, ctx| {
            if Instant::now().duration_since(act.last_heartbeat) > CLIENT_TIMEOUT {
                ctx.stop();
                return;
            }
            ctx.ping(b"");
        });
    }


    fn start_metrics_stream(&self, ctx: &mut ws::WebsocketContext<Self>) {
        let monitoring_service = self.monitoring_service.clone();
        let handle = ctx.run_interval(Duration::from_secs(1), move |actor, ctx| {
            let monitoring = monitoring_service.clone();
            
            let fut = async move {
                if let Some(metrics) = monitoring.get_current_metrics().await {
                    let message = json!({
                        "type": "resource_metrics",
                        "data": metrics,
                        "timestamp": chrono::Utc::now().to_rfc3339()  // timestamp 추가
                    });
                    message.to_string()
                } else {
                    let error_message = json!({
                        "type": "error",
                        "data": {
                            "message": "Failed to get metrics"
                        },
                        "timestamp": chrono::Utc::now().to_rfc3339()  // timestamp 추가
                    });
                    error_message.to_string()
                }            }
            .into_actor(actor)
            .map(|result, _, ctx| {
                if !result.is_empty() {
                    ctx.text(result);
                }
            });
            
            ctx.wait(fut);
        });

        if let Ok(mut handles) = self.subscription_handles.lock() {
            handles.insert("global".to_string(), handle);
        }
    }

    fn handle_server_subscription(
        &mut self,
        server_id: &str,
        ctx: &mut ws::WebsocketContext<Self>
    ) {
        // Cancel existing subscription if any
        if let Ok(handles) = self.subscription_handles.lock() {
            if let Some(handle) = handles.get(server_id) {
                ctx.cancel_future(*handle);
            }
        }

        self.server_id = Some(server_id.to_string());
        let monitoring_service = self.monitoring_service.clone();
        let server_id_owned = server_id.to_string();

        let handle = ctx.run_interval(Duration::from_secs(1), move |actor, ctx| {
            let monitoring = monitoring_service.clone();
            let server_id = server_id_owned.clone();
            
            let fut = async move {
                if let Some(metrics) = monitoring.get_server_metrics(&server_id).await {
                    let message = json!({
                        "type": "resource_metrics",
                        "server_id": server_id,
                        "data": metrics
                    });
                    message.to_string()
                } else {
                    json!({
                        "type": "error",
                        "data": {
                            "message": "Failed to get server metrics",
                            "server_id": server_id
                        }
                    }).to_string()
                }
            }
            .into_actor(actor)
            .map(|result, _, ctx| {
                if !result.is_empty() {
                    ctx.text(result);
                }
            });
            
            ctx.wait(fut);
        });

        // Save handle
        if let Ok(mut handles) = self.subscription_handles.lock() {
            handles.insert(server_id.to_string(), handle);
        }
    }
}

impl Actor for WebSocketConnection {
    type Context = ws::WebsocketContext<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        self.schedule_heartbeat(ctx);
        self.start_metrics_stream(ctx);
    }
}

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WebSocketConnection {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Ping(msg)) => {
                self.last_heartbeat = Instant::now();
                ctx.pong(&msg);
            }
            Ok(ws::Message::Pong(_)) => {
                self.last_heartbeat = Instant::now();
            }
            Ok(ws::Message::Text(text)) => {
                if let Ok(command) = serde_json::from_str::<serde_json::Value>(&text) {
                    if let Some(cmd_type) = command.get("type").and_then(|v| v.as_str()) {
                        match cmd_type {
                            "subscribe" => {
                                if let Some(server_id) = command.get("server_id").and_then(|v| v.as_str()) {
                                    self.handle_server_subscription(server_id, ctx);
                                }
                            }
                            "unsubscribe" => {
                                if let Some(server_id) = command.get("server_id").and_then(|v| v.as_str()) {
                                    if let Ok(mut handles) = self.subscription_handles.lock() {
                                        if let Some(handle) = handles.remove(server_id) {
                                            ctx.cancel_future(handle);
                                        }
                                    }
                                }
                                self.server_id = None;
                            }
                            _ => {}
                        }
                    }
                }
            }
            Ok(ws::Message::Close(reason)) => {
                ctx.close(reason);
                ctx.stop();
            }
            _ => {}
        }
    }
}

#[derive(Message)]
#[rtype(result = "()")]
pub struct MetricsMessage(pub MetricsSnapshot);

impl Handler<MetricsMessage> for WebSocketConnection {
    type Result = ();

    fn handle(&mut self, msg: MetricsMessage, ctx: &mut Self::Context) {
        if let Some(metrics_json) = serde_json::to_string(&msg.0).ok() {
            ctx.text(metrics_json);
        }
    }
}