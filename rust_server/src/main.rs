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
   // Environment setup
   dotenv().ok();
   setup_logging();
   
   // Database setup
   let db_pool = setup_database().await.map_err(|e| {
       std::io::Error::new(std::io::ErrorKind::Other, e.to_string())
   })?;
   let repository = Arc::new(Repository::new(db_pool));
   
   // Services setup
   let monitoring_service = MonitoringService::new(repository.clone());

   // Server setup
   HttpServer::new(move || {
       App::new()
           .wrap(setup_cors())
           .wrap(middleware::Logger::default())
           //.wrap(AuthenticationMiddleware)
           .app_data(web::Data::new(repository.clone()))
           .app_data(web::Data::new(monitoring_service.clone()))
           .configure(api::configure_routes)
           .configure(websocket::configure_routes)
   })
   .bind("0.0.0.0:8080")?
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
        .map_err(|e| AppError::Database(e.to_string()))?;

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