// src/main.rs
use actix_web::{web, App, HttpServer, middleware};
use actix_cors::Cors;
use dotenv::dotenv;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use std::sync::Arc;

use rust_server::{
   api,
   //auth::AuthenticationMiddleware,
   db::{self, repository::Repository, DbPool},
   monitoring::MonitoringService,
   websocket,
   error::AppError,
};

mod auth;
mod models;
mod monitoring;
mod error;
mod config;

#[actix_web::main]
async fn main() -> Result<(), std::io::Error> {
    dotenv().ok();
    setup_logging();
    
    let db_pool = setup_database().await.map_err(|e| {
        std::io::Error::new(std::io::ErrorKind::Other, e.to_string())
    })?;
    
    // Arc로 Repository 생성
    let repository = Arc::new(Repository::new(db_pool));
    
    // 두 서비스 모두 Arc<Repository>를 사용하도록 설정
    let app_repository = web::Data::new(repository.clone());
    let monitoring_service = web::Data::new(MonitoringService::new(repository));

    // Server address setup
    let host = std::env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT must be a number");
    let server_address = format!("{}:{}", host, port);

    HttpServer::new(move || {
        App::new()
            .wrap(middleware::Logger::default())
            .wrap(setup_cors())
            .app_data(app_repository.clone())            // app_data로 전달
            .app_data(monitoring_service.clone())        // app_data로 전달
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