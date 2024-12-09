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
const METRICS_INTERVAL: Duration = Duration::from_secs(1);

#[derive(Message)]
#[rtype(result = "()")]
struct HeartbeatTimeout;

#[derive(Message)]
#[rtype(result = "()")]
pub struct ServerMetrics {
    pub server_id: String,
    pub metrics: MetricsSnapshot,
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

    fn schedule_heartbeat(&mut self, ctx: &mut ws::WebsocketContext<Self>) {
        let addr = ctx.address();
        let heartbeat = ctx.run_interval(HEARTBEAT_INTERVAL, move |act, ctx| {
            if Instant::now().duration_since(act.last_heartbeat) > CLIENT_TIMEOUT {
                addr.do_send(HeartbeatTimeout);
                ctx.stop();
                return;
            }
            ctx.ping(b"");
        });

        if let Ok(mut handles) = self.subscription_handles.lock() {
            handles.insert("heartbeat".to_string(), heartbeat);
        }
    }

    fn send_metrics(&mut self, ctx: &mut ws::WebsocketContext<Self>) {
        if let Some(server_id) = self.server_id.clone() {
            let monitoring = self.monitoring_service.clone();
            let server_id_for_fut = server_id.clone();
    
            let fut = async move {
                println!("Getting metrics for server: {}", server_id_for_fut);
                if let Some(metrics) = monitoring.get_server_metrics(&server_id_for_fut).await {
                    println!("Got metrics: CPU: {}%, Memory: {}%, Disk: {}%",
                        metrics.cpu_usage,
                        metrics.memory_usage,
                        metrics.disk_usage
                    );
                    
                    let message = json!({
                        "type": "resource_metrics",
                        "data": {
                            "serverId": server_id_for_fut,
                            "cpuUsage": metrics.cpu_usage,
                            "memoryUsage": metrics.memory_usage,
                            "diskUsage": metrics.disk_usage,
                            "networkUsage": (metrics.network_rx as f64 + metrics.network_tx as f64) / 2.0,
                            "processCount": metrics.processes.len(),
                            "processes": metrics.processes,
                            "timestamp": chrono::Utc::now().to_rfc3339()
                        }
                    });
                    Ok(message.to_string())
                } else {
                    println!("No metrics available for server: {}", server_id_for_fut);
                    Err("No metrics available")
                }
            };
    
            let server_id_for_error = server_id.clone();
            ctx.spawn(fut.into_actor(self).map(move |res, _, ctx| {
                match res {
                    Ok(msg) => ctx.text(msg),
                    Err(e) => {
                        let error_message = json!({
                            "type": "error",
                            "data": {
                                "message": e,
                                "serverId": server_id_for_error
                            }
                        });
                        ctx.text(error_message.to_string());
                    }
                }
            }));
        }
    }

    fn start_metrics_stream(&mut self, ctx: &mut ws::WebsocketContext<Self>) {
        let server_id = self.server_id.clone();
        if let Some(server_id) = server_id {
            let handle = ctx.run_interval(METRICS_INTERVAL, move |act, ctx| {
                act.send_metrics(ctx);
            });

            if let Ok(mut handles) = self.subscription_handles.lock() {
                handles.insert(format!("metrics_{}", server_id), handle);
            }
        }
    }

    fn stop_metrics_stream(&mut self) {
        if let Some(server_id) = &self.server_id {
            if let Ok(mut handles) = self.subscription_handles.lock() {
                handles.remove(&format!("metrics_{}", server_id));
            }
        }
    }

    // fn handle_server_subscription(
    //     &mut self,
    //     server_id: String,
    //     ctx: &mut ws::WebsocketContext<Self>,
    // ) {
    //     if let Ok(mut handles) = self.subscription_handles.lock() {
    //         if let Some(handle) = handles.remove("metrics_stream") {
    //             ctx.cancel_future(handle);
    //         }
    //     }

    //     self.server_id = Some(server_id);
    //     self.start_metrics_stream(ctx);
    // }
}



impl Handler<HeartbeatTimeout> for WebSocketConnection {
    type Result = ();

    fn handle(&mut self, _: HeartbeatTimeout, ctx: &mut Self::Context) {
        ctx.stop();
    }
}

impl Handler<ServerMetrics> for WebSocketConnection {
    type Result = ();

    fn handle(&mut self, msg: ServerMetrics, ctx: &mut Self::Context) {
        if let Some(ref current_server_id) = self.server_id {
            if current_server_id == &msg.server_id {
                let message = json!({
                    "type": "server_metrics.update",
                    "data": {
                        "server_id": msg.server_id,
                        "metrics": msg.metrics
                    }
                });
                
                if let Ok(json_str) = serde_json::to_string(&message) {
                    ctx.text(json_str);
                }
            }
        }
    }
}

impl Actor for WebSocketConnection {
    type Context = ws::WebsocketContext<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        self.schedule_heartbeat(ctx);
    }

    fn stopped(&mut self, _: &mut Self::Context) {
        self.stop_metrics_stream();
    }
}

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WebSocketConnection {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        println!("WebSocket message received: {:?}", msg);
        match msg {
            Ok(ws::Message::Ping(msg)) => {
                println!("Ping received");
                self.last_heartbeat = Instant::now();
                ctx.pong(&msg);
            }
            Ok(ws::Message::Pong(_)) => {
                println!("Pong received");
                self.last_heartbeat = Instant::now();
            }
            Ok(ws::Message::Text(text)) => {
                println!("Text message received: {}", text);
                if let Ok(command) = serde_json::from_str::<serde_json::Value>(&text) {
                    println!("Parsed command: {:?}", command);
                    if let Some(cmd_type) = command.get("type").and_then(|v| v.as_str()) {
                        println!("Command type: {}", cmd_type);
                        match cmd_type {
                            "server_metrics.subscribe" => {
                                if let Some(server_id) = command
                                    .get("data")
                                    .and_then(|d| d.get("server_id"))
                                    .and_then(|s| s.as_str())
                                {
                                    println!("Subscribing to metrics for server: {}", server_id);
                                    self.stop_metrics_stream();
                                    self.server_id = Some(server_id.to_string());
                                    self.start_metrics_stream(ctx);
                                }
                            }
                            "server_metrics.unsubscribe" => {
                                println!("Unsubscribing from metrics");
                                self.stop_metrics_stream();
                                self.server_id = None;
                            }
                            _ => {
                                println!("Unknown command type: {}", cmd_type);
                            }
                        }
                    }
                }
            }
            Ok(ws::Message::Close(reason)) => {
                println!("Close message received: {:?}", reason);
                ctx.close(reason);
                ctx.stop();
            }
            _ => {
                println!("Other message type received");
            }
        }
    }
}