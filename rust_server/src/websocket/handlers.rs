// src/websocket/handlers.rs
use actix::{
    Actor, ActorContext, AsyncContext, Handler, Message, StreamHandler, 
    SpawnHandle, WrapFuture, ActorFutureExt,
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

#[derive(Message)]
#[rtype(result = "()")]
pub struct MetricsMessage(pub MetricsSnapshot);

#[derive(Message)]
#[rtype(result = "()")]
struct MetricsRequest {
    monitoring: Option<MonitoringService>,
    server_id: Option<String>,
}

pub struct WebSocketConnection {
    last_heartbeat: Instant,
    monitoring_service: MonitoringService,
    subscription_handles: Arc<Mutex<HashMap<String, SpawnHandle>>>,
    server_id: Option<String>,
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
        let _heartbeat = Instant::now();
        ctx.run_interval(HEARTBEAT_INTERVAL, move |act, ctx| {
            if Instant::now().duration_since(act.last_heartbeat) > CLIENT_TIMEOUT {
                ctx.stop();
                return;
            }
            ctx.ping(b"");
        });
    }

    fn send_metrics(&self, metrics: Option<MonitoringService>, server_id: Option<String>, ctx: &mut ws::WebsocketContext<Self>) {
        if let Some(metrics) = metrics {
            let monitoring = metrics.clone();
            let current_server_id = server_id.clone();

            let fut = async move {
                if let Some(metrics_data) = monitoring.get_current_metrics().await {
                    let network_usage = (metrics_data.network_rx as f64 + metrics_data.network_tx as f64) / 2.0;
                    
                    let message = json!({
                        "type": "resource_metrics",
                        "data": {
                            "serverId": current_server_id.unwrap_or_else(|| "global".to_string()),
                            "cpuUsage": metrics_data.cpu_usage as f64,
                            "memoryUsage": metrics_data.memory_usage as f64,
                            "diskUsage": metrics_data.disk_usage as f64,
                            "networkUsage": network_usage,
                            "processCount": metrics_data.processes.len(),
                            "processes": metrics_data.processes.iter().map(|p| {
                                json!({
                                    "pid": p.pid,
                                    "name": p.name.clone(),
                                    "cpuUsage": p.cpu_usage,
                                    "memoryUsage": p.memory_usage
                                })
                            }).collect::<Vec<_>>(),
                            "timestamp": chrono::Utc::now().to_rfc3339()
                        }
                    });
                    Ok(message.to_string())
                } else {
                    Err("Failed to get metrics")
                }
            };

            ctx.spawn(
                fut.into_actor(self)
                    .map(move |res, _, ctx| {
                        match res {
                            Ok(msg) => ctx.text(msg),
                            Err(e) => {
                                let error_message = json!({
                                    "type": "error",
                                    "data": {
                                        "message": e,
                                        "serverId": server_id.unwrap_or_else(|| "global".to_string())
                                    },
                                    "timestamp": chrono::Utc::now().to_rfc3339()
                                });
                                ctx.text(error_message.to_string());
                            }
                        }
                    })
            );
        }
    }

    fn start_metrics_stream(&mut self, ctx: &mut ws::WebsocketContext<Self>) {
        let monitoring_service = self.monitoring_service.clone();
        let server_id = self.server_id.clone();

        let handle = ctx.run_interval(Duration::from_secs(1), move |_, ctx| {
            ctx.address().do_send(MetricsRequest {
                monitoring: Some(monitoring_service.clone()),
                server_id: server_id.clone(),
            });
        });

        if let Ok(mut handles) = self.subscription_handles.lock() {
            handles.insert("metrics_stream".to_string(), handle);
        }
    }

    fn handle_server_subscription(
        &mut self,
        server_id: String,
        ctx: &mut ws::WebsocketContext<Self>,
    ) {
        if let Ok(mut handles) = self.subscription_handles.lock() {
            if let Some(handle) = handles.remove("metrics_stream") {
                ctx.cancel_future(handle);
            }
        }

        self.server_id = Some(server_id);
        self.start_metrics_stream(ctx);
    }
}

impl Handler<MetricsRequest> for WebSocketConnection {
    type Result = ();

    fn handle(&mut self, msg: MetricsRequest, ctx: &mut Self::Context) {
        self.send_metrics(msg.monitoring, msg.server_id, ctx);
    }
}

impl Handler<MetricsMessage> for WebSocketConnection {
    type Result = ();

    fn handle(&mut self, msg: MetricsMessage, ctx: &mut Self::Context) {
        if let Some(metrics_json) = serde_json::to_string(&msg.0).ok() {
            ctx.text(metrics_json);
        }
    }
}

impl Actor for WebSocketConnection {
    type Context = ws::WebsocketContext<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        self.schedule_heartbeat(ctx);
        self.start_metrics_stream(ctx);
    }

    fn stopped(&mut self, _: &mut Self::Context) {
        if let Ok(mut handles) = self.subscription_handles.lock() {
            handles.clear();
        }
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
                            "resource_metrics" => {
                                if let Some(server_id) = command
                                    .get("data")
                                    .and_then(|d| d.get("serverId"))
                                    .and_then(|s| s.as_str()) 
                                {
                                    self.handle_server_subscription(server_id.to_string(), ctx);
                                }
                            }
                            "unsubscribe" => {
                                if let Ok(mut handles) = self.subscription_handles.lock() {
                                    handles.clear();
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