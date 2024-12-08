// src/main.rs
use actix_web::{web, App, HttpServer, HttpResponse};
use actix_web::middleware::{Logger, Compress};
use actix_cors::Cors;
use dotenv::dotenv;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use rust_server::{
    api::configure_routes,
    auth::middleware::AuthMiddleware, 
    db::{self, repository::Repository},
    monitoring::MonitoringService,
    error::AppError,
    config::ServerConfig,
};


#[actix_web::main]
async fn main() -> Result<(), std::io::Error> {
    dotenv().ok();
    setup_logging();

    // 설정 초기화
    let config = web::Data::new(ServerConfig::with_defaults());
    
    // 데이터베이스 설정
    let db_pool = setup_database().await.map_err(|e| {
        std::io::Error::new(std::io::ErrorKind::Other, e.to_string())
    })?;
    
    println!("JWT_SECRET: {}", std::env::var("JWT_SECRET").unwrap_or_default());
    println!("ENCRYPTION_KEY: {}", std::env::var("ENCRYPTION_KEY").unwrap_or_default());
    println!("ENCRYPTION_NONCE: {}", std::env::var("ENCRYPTION_NONCE").unwrap_or_default());

    // 서비스 초기화
    let repository = web::Data::new(Repository::new(db_pool));
    let monitoring_service = web::Data::new(MonitoringService::new(repository.clone()));
    let http_client = web::Data::new(reqwest::Client::new());

    let server_address = format!("{}:{}", 
        config.server.host, 
        config.server.port
    );

    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .wrap(Compress::default())  // Compression -> Compress로 수정
            .wrap(setup_cors())
            .wrap(AuthMiddleware)
            .app_data(config.clone())
            .app_data(repository.clone())
            .app_data(monitoring_service.clone())
            .app_data(http_client.clone())
            .configure(configure_routes)
            .default_service(web::route().to(|| async { HttpResponse::NotFound().finish() }))
    })
    .bind(&server_address)?
    .run()
    .await
}

fn setup_cors() -> Cors {
    Cors::default()
        .allow_any_origin()
        .allowed_methods(vec!["GET", "POST", "PUT", "DELETE"])
        .allow_any_header()
        .supports_credentials()
        .allow_any_method()
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

async fn setup_database() -> Result<db::DbPool, AppError> {
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    // 데이터베이스 연결 테스트
    db::test_connection(&database_url).await?;
    
    // SQLx 마이그레이션 실행
    let pool = db::create_pool().await?;
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .map_err(|e| AppError::DatabaseError(sqlx::Error::from(e)))?;

    Ok(pool)
}

fn setup_logging() {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();
}
