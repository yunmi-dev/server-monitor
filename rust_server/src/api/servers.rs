// src/api/servers.rs
use actix_web::{web, HttpResponse, Result};
use chrono::{DateTime, Utc};
use uuid::Uuid;
use ssh2::Session;
use tokio::net::{TcpStream, lookup_host};
use std::time::Duration;
use std::io::Read;
use crate::db::{models::{Server, ServerType}, repository::Repository};

#[derive(serde::Deserialize)]
pub struct CreateServerRequest {
    pub name: String,
    pub host: String,
    pub port: i32,
    pub username: String,
    pub password: String,
    pub server_type: ServerType,
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
struct TestConnectionResponse {
    success: bool,
    message: String,
    details: Option<ConnectionDetails>,
}

#[derive(serde::Serialize)]
struct ConnectionDetails {
    dns_resolved: bool,
    tcp_connected: bool,
    ssh_authenticated: bool,
    latency_ms: u64,
    server_version: Option<String>,
}

// 서버 생성
pub async fn create_server(
    repo: web::Data<Repository>,
    server_info: web::Json<CreateServerRequest>,
) -> Result<HttpResponse> {
    let server = Server {
        id: Uuid::new_v4().to_string(),
        name: server_info.name.clone(),
        hostname: server_info.host.clone(),
        ip_address: server_info.host.clone(),
        location: "Unknown".to_string(),
        server_type: server_info.server_type.clone(),
        is_online: false,
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    let result = repo.create_server(server).await
        .map_err(|e| actix_web::error::ErrorInternalServerError(e))?;

    Ok(HttpResponse::Created().json(result))
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
) -> Result<HttpResponse> {
    let start_time = std::time::Instant::now();
    let dns_timeout = Duration::from_secs(5);
    let tcp_timeout = Duration::from_secs(5);

    let mut details = ConnectionDetails {
        dns_resolved: false,
        tcp_connected: false,
        ssh_authenticated: false,
        latency_ms: 0,
        server_version: None,
    };

    // TCP 연결 테스트 전에 호스트 검증 추가
    if connection_info.host == "127.0.0.1" {
        return Ok(HttpResponse::BadRequest().json(TestConnectionResponse {
            success: false,
            message: "For security reasons, connections to localhost are not allowed".to_string(),
            details: Some(details),
        }));
    }

    // 1. DNS 조회 테스트
    let lookup_result = match tokio::time::timeout(
        dns_timeout,
        lookup_host(format!("{}:{}", connection_info.host, connection_info.port))
    ).await {
        Ok(Ok(addrs)) => {
            details.dns_resolved = true;
            Ok(addrs.collect::<Vec<_>>())
        },
        Ok(Err(e)) => Err(format!("DNS lookup failed: {}", e)),
        Err(_) => Err("DNS lookup timed out".to_string()),
    };

    if let Err(e) = lookup_result {
        return Ok(HttpResponse::BadRequest().json(TestConnectionResponse {
            success: false,
            message: e,
            details: Some(details),
        }));
    }

    // 2. TCP 연결 테스트
    let tcp_result = match tokio::time::timeout(
        tcp_timeout,  // timeout 대신 tcp_timeout 사용
        TcpStream::connect(format!("{}:{}", connection_info.host, connection_info.port))
    ).await {
        Ok(Ok(stream)) => {
            details.tcp_connected = true;
            Ok(stream)
        },
        Ok(Err(e)) => Err(format!("TCP connection failed: {}", e)),
        Err(_) => Err("TCP connection timed out".to_string()),
    };

    let tcp_stream = match tcp_result {
        Ok(stream) => stream,
        Err(e) => {
            return Ok(HttpResponse::BadRequest().json(TestConnectionResponse {
                success: false,
                message: e,
                details: Some(details),
            }));
        }
    };

    // 3. SSH 연결 및 인증 테스트
    let ssh_result = tokio::task::spawn_blocking(move || -> Result<(Session, Option<String>), String> {
        let mut session = match Session::new() {
            Ok(session) => session,
            Err(e) => return Err(format!("Failed to create SSH session: {}", e)),
        };

        session.set_tcp_stream(tcp_stream);
        
        if let Err(e) = session.handshake() {
            return Err(format!("SSH handshake failed: {}", e));
        }

        let server_version = session.banner().map(|b| b.to_string());
        
        if let Err(e) = session.userauth_password(&connection_info.username, &connection_info.password) {
            return Err(format!("Authentication failed: {}", e));
        }

        let mut channel = match session.channel_session() {
            Ok(channel) => channel,
            Err(e) => return Err(format!("Failed to create channel: {}", e)),
        };

        if let Err(e) = channel.exec("echo test") {
            return Err(format!("Failed to execute command: {}", e));
        }
        
        let mut output = String::new();
        if let Err(e) = channel.read_to_string(&mut output) {
            return Err(format!("Failed to read output: {}", e));
        }

        if let Err(e) = channel.wait_close() {
            return Err(format!("Failed to close channel: {}", e));
        }

        Ok((session, server_version))
    }).await;

    details.latency_ms = start_time.elapsed().as_millis() as u64;

    match ssh_result {
        Ok(Ok((_, server_version))) => {
            details.ssh_authenticated = true;
            details.server_version = server_version;
            
            Ok(HttpResponse::Ok().json(TestConnectionResponse {
                success: true,
                message: "Successfully connected and authenticated".to_string(),
                details: Some(details),
            }))
        },
        Ok(Err(e)) => {
            Ok(HttpResponse::BadRequest().json(TestConnectionResponse {
                success: false,
                message: e,
                details: Some(details),
            }))
        },
        Err(e) => {
            Ok(HttpResponse::InternalServerError().json(TestConnectionResponse {
                success: false,
                message: format!("Internal error during SSH test: {}", e),
                details: Some(details),
            }))
        }
    }
}