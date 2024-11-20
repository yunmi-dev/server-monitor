// src/config.rs
use serde::Deserialize;
use ::config::{Config, ConfigError, Environment, File};

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct ServerConfig {
    pub server: HttpServerConfig,
    pub database: DatabaseConfig,
    pub auth: AuthConfig,
    pub monitoring: MonitoringConfig,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct HttpServerConfig {
    pub host: String,
    pub port: u16,
    pub cors_origins: Vec<String>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub timeout_seconds: u64,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct AuthConfig {
    pub jwt_secret: String,
    pub token_expiration_hours: i64,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct MonitoringConfig {
    pub metrics_interval_seconds: u64,
    pub retention_days: i64,
    pub alert_thresholds: AlertThresholds,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct AlertThresholds {
    pub cpu_warning: f32,
    pub cpu_critical: f32,
    pub memory_warning: f32,
    pub memory_critical: f32,
    pub disk_warning: f32,
    pub disk_critical: f32,
}

#[allow(dead_code)]
impl ServerConfig {
    pub fn new() -> Result<Self, ConfigError> {
        let builder = Config::builder()
            .add_source(File::with_name("config/default"))
            .add_source(File::with_name("config/local").required(false))
            .add_source(Environment::with_prefix("APP"));

        builder.build()?.try_deserialize()
    }
}