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
    
    let config = ServerConfig::with_defaults();
    let app_config = web::Data::new(config);

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
            .app_data(app_config.clone())
            .app_data(app_repository.clone())
            .app_data(monitoring_service.clone())
            .app_data(http_client.clone())
            .configure(api::configure_routes)
    })
    .bind(&server_address)?
    .run()
    .await
}

fn setup_cors() -> Cors {
   Cors::default()
       .allow_any_origin()
       .allow_any_method()
       .allow_any_header()
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