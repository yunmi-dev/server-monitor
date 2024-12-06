// src/main.rs
use actix_web::{web, App, HttpServer};
use actix_web::middleware::Logger;
use actix_cors::Cors;
use dotenv::dotenv;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use std::sync::Arc;

use rust_server::{
    api,
    auth::middleware::AuthMiddleware, 
    db::{self, repository::Repository, DbPool},
    monitoring::MonitoringService,
    error::AppError,
    config::ServerConfig,
};

#[actix_web::main]
async fn main() -> Result<(), std::io::Error> {
    dotenv().ok();
    setup_logging();


    // src/main.rs나 적절한 시작 지점에서
    println!("JWT_SECRET: {}", std::env::var("JWT_SECRET").unwrap_or_default());
    println!("ENCRYPTION_KEY: {}", std::env::var("ENCRYPTION_KEY").unwrap_or_default());
    println!("ENCRYPTION_NONCE: {}", std::env::var("ENCRYPTION_NONCE").unwrap_or_default());


    
    let config = web::Data::new(ServerConfig::with_defaults());  // web::Data로 직접 감싸기
    
    let db_pool = setup_database().await.map_err(|e| {
        std::io::Error::new(std::io::ErrorKind::Other, e.to_string())
    })?;
    
    let repository = Arc::new(Repository::new(db_pool));
    let app_repository = web::Data::new(repository.clone());
    let monitoring_service = web::Data::new(MonitoringService::new(repository));

    // HTTP client for social login
    let http_client = web::Data::new(reqwest::Client::new());

    let host = std::env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT must be a number");
    let server_address = format!("{}:{}", host, port);

    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .wrap(setup_cors())
            .wrap(AuthMiddleware)
            .app_data(config.clone())        // config 직접 사용
            .app_data(app_repository.clone())
            .app_data(monitoring_service.clone())
            .app_data(http_client.clone())
            .configure(api::configure_routes)
    })
    .bind(&server_address)?
    .run()
    .await
}
// http 2 는 헤더 사용 금지임 - 나 http 몇이야?

fn setup_cors() -> Cors {
    Cors::default()
        .allow_any_origin()  // 개발 중에는 모든 오리진 허용
        .allowed_methods(vec!["GET", "POST", "PUT", "DELETE"])
        .allow_any_header()  // 모든 헤더 허용
        .supports_credentials()
        .allow_any_method()
        // WebSocket 관련 헤더 명시적 허용
        .allowed_headers(vec![
            "sec-websocket-key",
            "sec-websocket-protocol",
            "sec-websocket-version",
            "upgrade",
            "connection"
        ])
        .expose_headers(vec!["sec-websocket-accept"])
        .max_age(3600)
}

async fn setup_database() -> Result<DbPool, AppError> {
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    // 데이터베이스 연결 테스트
    db::test_connection(&database_url).await?;
    
    // SQLx 마이그레이션 실행
    sqlx::migrate!("./migrations")
        .run(&db::create_pool().await?)
        .await
        .map_err(|e| AppError::DatabaseError(sqlx::Error::from(e)))?;


    // 풀 생성 및 반환
    db::create_pool().await.map_err(AppError::from)
}

fn setup_logging() {
   tracing_subscriber::registry()
       .with(tracing_subscriber::EnvFilter::new(
           std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
       ))
       .with(tracing_subscriber::fmt::layer())
       .init();
}