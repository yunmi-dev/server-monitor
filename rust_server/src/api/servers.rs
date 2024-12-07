// src/api/servers.rs
use actix_web::{web, HttpResponse, Result, error::ResponseError};
use chrono::{DateTime, Utc};
use uuid::Uuid;
use ssh2::Session;
use tokio::net::TcpStream;
use tokio::time::timeout;
use std::time::Duration;
use std::sync::Arc;
use std::fmt;
use serde_json::json;
use tracing::{debug, info};
use crate::db::{models::{Server, ServerType}, repository::Repository};
use crate::models::logs::LogEntry;
use crate::config::ServerConfig;
use crate::utils::encryption::Encryptor;

#[derive(serde::Deserialize, Debug)]
#[serde(rename_all = "lowercase")]
pub struct CreateServerRequest {
    pub name: String,
    pub host: String,
    pub port: i32,
    pub username: String,
    pub password: String,
    #[serde(rename = "type")]
    pub server_type: ServerType,
    #[serde(skip)]
    pub category: Option<String>,
}

#[derive(serde::Deserialize)]
pub struct TestConnectionRequest {
    pub host: String,
    pub port: i32,
    pub username: String,
    pub password: String,
}

#[derive(serde::Deserialize)]
pub struct UpdateServerStatusRequest {
    pub is_online: bool,
}

#[derive(serde::Serialize)]
pub struct ServerStatus {
    pub cpu_usage: f64,
    pub memory_usage: f64,
    pub disk_usage: f64,
    pub uptime: i64,
    pub processes: Vec<ProcessInfo>,
    pub is_online: bool,
}

#[derive(serde::Serialize)]
pub struct ServerStatusResponse {
    pub id: String,
    pub name: String,
    pub status: String,
    pub resources: ResourceUsage,
    pub uptime: String,
    pub processes: Vec<ProcessInfo>,
    pub recent_logs: Vec<LogEntry>,
}

#[derive(serde::Serialize)]
pub struct ProcessInfo {
    pub pid: i32,
    pub name: String,
    pub cpu_usage: f64,
    pub memory_usage: f64,
}

#[derive(serde::Serialize)]
pub struct ResourceUsage {
    pub cpu: f64,
    pub memory: f64,
    pub disk: f64,
    pub network: String,
    pub history: Vec<ResourceHistory>,
    pub last_updated: Option<DateTime<Utc>>,
}

#[derive(serde::Serialize)]
pub struct ResourceHistory {
    pub timestamp: DateTime<Utc>,
    pub cpu: f64,
    pub memory: f64,
    pub disk: f64,
    pub network: String,
}


// 커스텀 에러 타입 정의
#[derive(Debug)]
pub enum ServerError {
    ConnectionFailed(String),
    ValidationFailed(String),
    InternalError(String),
}

impl fmt::Display for ServerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ServerError::ConnectionFailed(msg) => write!(f, "Connection failed: {}", msg),
            ServerError::ValidationFailed(msg) => write!(f, "Validation failed: {}", msg),
            ServerError::InternalError(msg) => write!(f, "Internal error: {}", msg),
        }
    }
}

impl ResponseError for ServerError {
    fn error_response(&self) -> HttpResponse {
        match self {
            ServerError::ConnectionFailed(msg) => HttpResponse::BadRequest().json(json!({
                "success": false,
                "message": msg
            })),
            ServerError::ValidationFailed(msg) => HttpResponse::BadRequest().json(json!({
                "success": false,
                "message": msg
            })),
            ServerError::InternalError(msg) => HttpResponse::InternalServerError().json(json!({
                "success": false,
                "message": msg
            })),
        }
    }
}

// 서버 생성
pub async fn create_server(
    repo: web::Data<Repository>,
    server_info: web::Json<CreateServerRequest>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse> {
    // 1. 입력값 검증
    if server_info.name.is_empty() || server_info.host.is_empty() {
        return Ok(HttpResponse::BadRequest().json(json!({
            "error": "Invalid input parameters"
        })));
    }

    // 2. 중복 확인
    if let Ok(Some(_)) = repo.get_server_by_hostname(&server_info.host).await {
        return Ok(HttpResponse::Conflict().json(json!({
            "error": "Server with this hostname already exists"
        })));
    }

    // 3. 비밀번호 암호화
    let encryptor = Encryptor::new(&config.encryption.key, &config.encryption.nonce)?;
    let encrypted_password = encryptor.encrypt(&server_info.password)?;

    // 4. 서버 생성
    let server = Server {
        id: Uuid::new_v4().to_string(),
        name: server_info.name.clone(),
        hostname: server_info.host.clone(),
        port: server_info.port,
        username: server_info.username.clone(),
        encrypted_password,
        server_type: server_info.server_type.clone(),
        created_at: Utc::now(),
        updated_at: Utc::now(),
        ..Default::default()
    };

    // 5. DB에 저장
    match repo.create_server(server).await {
        Ok(created_server) => Ok(HttpResponse::Created().json(created_server)),
        Err(e) => Ok(HttpResponse::InternalServerError().json(json!({
            "error": format!("Failed to create server: {}", e)
        }))),
    }
}

// 서버 목록 조회
pub async fn get_servers(
    repo: web::Data<Repository>,
) -> Result<HttpResponse> {
    let servers = repo.list_servers().await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;

    Ok(HttpResponse::Ok().json(servers))
}

// 특정 서버 조회
pub async fn get_server(
    repo: web::Data<Repository>,
    server_id: web::Path<String>,
) -> Result<HttpResponse> {
    let server = repo.get_server(&server_id).await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;

    match server {
        Some(server) => Ok(HttpResponse::Ok().json(server)),
        None => Ok(HttpResponse::NotFound().finish()),
    }
}

// 서버 상태 업데이트
pub async fn update_server_status(
    repo: web::Data<Repository>,
    server_id: web::Path<String>,
    status: web::Json<UpdateServerStatusRequest>,
) -> Result<HttpResponse> {
    repo.update_server_status(&server_id, status.is_online).await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;

    Ok(HttpResponse::Ok().finish())
}

// 서버 상태 가져오기
pub async fn get_server_status(
    repo: web::Data<Arc<Repository>>,
    server_id: web::Path<String>,
) -> Result<HttpResponse> {
    let server = match repo.get_server(&server_id).await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))? {
        Some(server) => server,
        None => return Ok(HttpResponse::NotFound().finish()),
    };

    let status = ServerStatusResponse {
        id: server.id.clone(),
        name: server.name.clone(),
        resources: ResourceUsage {
            cpu: 0.0,
            memory: 0.0,
            disk: 0.0,
            network: "0 B/s".to_string(),
            history: vec![],
            last_updated: None,
        },
        status: if server.is_online { "online" } else { "offline" }.to_string(),
        uptime: "0s".to_string(),
        processes: vec![],
        recent_logs: vec![],
    };

    Ok(HttpResponse::Ok().json(status))
}

// 서버 삭제
pub async fn delete_server(
    repo: web::Data<Repository>,
    server_id: web::Path<String>,
) -> Result<HttpResponse> {
    repo.delete_server(&server_id).await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;

    Ok(HttpResponse::NoContent().finish())
}

#[derive(serde::Deserialize)]
pub struct MetricsQueryParams {
    pub from: DateTime<Utc>,
    pub to: DateTime<Utc>,
}

// 서버 메트릭 조회
pub async fn get_server_metrics(
    repo: web::Data<Repository>,
    server_id: web::Path<String>,
    query: web::Query<MetricsQueryParams>,
) -> Result<HttpResponse> {
    let metrics = repo.get_server_metrics(&server_id, query.from, query.to).await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;

    Ok(HttpResponse::Ok().json(metrics))
}

// 연결 테스트

pub async fn test_connection(
    connection_info: web::Json<TestConnectionRequest>,
) -> Result<HttpResponse, ServerError> {
    let start_time = std::time::Instant::now();
    debug!("Starting connection test to {}:{}", connection_info.host, connection_info.port);

    // 1. 입력값 검증
    if connection_info.host.is_empty() || connection_info.username.is_empty() {
        return Err(ServerError::ValidationFailed(
            "Host and username cannot be empty".to_string()
        ));
    }

    if connection_info.port <= 0 || connection_info.port > 65535 {
        return Err(ServerError::ValidationFailed(
            "Invalid port number".to_string()
        ));
    }

    // 2. DNS 조회
    let addr = match timeout(
        Duration::from_secs(30),
        tokio::net::lookup_host(format!("{}:{}", connection_info.host, connection_info.port))
    ).await {
        Ok(Ok(mut addrs)) => match addrs.next() {
            Some(addr) => {
                debug!("DNS resolution successful: {}", addr);
                addr
            },
            None => return Err(ServerError::ConnectionFailed(
                "Could not resolve hostname".to_string()
            )),
        },
        _ => return Err(ServerError::ConnectionFailed(
            "DNS lookup failed - please check the hostname".to_string()
        )),
    };

    // 3. TCP 연결
    let tcp_stream = match timeout(
        Duration::from_secs(30),
        TcpStream::connect(&addr)
    ).await {
        Ok(Ok(stream)) => {
            debug!("TCP connection established to {}", addr);
            stream
        },
        Ok(Err(e)) => return Err(ServerError::ConnectionFailed(
            format!("Cannot connect to server: {}. Please check if the port is open and server is reachable.", e)
        )),
        Err(_) => return Err(ServerError::ConnectionFailed(
            "Connection timed out - server is not responding".to_string()
        )),
    };

    // 4. SSH 연결
    let connection_info = connection_info.into_inner();
    let _ssh_result = tokio::task::spawn_blocking(move || -> Result<(), ServerError> {
        let mut session = Session::new().map_err(|e| 
            ServerError::InternalError(format!("SSH session creation failed: {}", e))
        )?;
        
        session.set_tcp_stream(tcp_stream);
        debug!("Starting SSH handshake");
        
        session.set_timeout(30000); // 30 seconds
        
        if let Err(e) = session.handshake() {
            return Err(ServerError::ConnectionFailed(
                format!("SSH handshake failed: {}. Please check if SSH service is running.", e)
            ));
        }
        
        debug!("SSH handshake successful, attempting authentication");
        
        if let Err(e) = session.userauth_password(&connection_info.username, &connection_info.password) {
            return Err(ServerError::ConnectionFailed(
                format!("Authentication failed: {}. Please check username and password.", e)
            ));
        }
        
        debug!("SSH authentication successful");
        Ok(())
    }).await.map_err(|e| ServerError::InternalError(
        format!("Task join error: {}", e)
    ))??;

    let elapsed = start_time.elapsed().as_millis() as u64;
    info!("Connection test successful ({}ms)", elapsed);
    
    Ok(HttpResponse::Ok().json(json!({
        "success": true,
        "message": "Connection successful",
        "latency_ms": elapsed
    })))
}