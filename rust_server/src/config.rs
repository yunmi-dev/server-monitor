// src/config.rs
use serde::Deserialize;

pub use self::ServerConfig as Config;

#[derive(Debug, Deserialize, Clone)]
pub struct ServerConfig {
    pub server: HttpServerConfig,
    pub database: DatabaseConfig,
    pub auth: AuthConfig,
    pub monitoring: MonitoringConfig,
    pub encryption: EncryptionConfig,
}

#[derive(Debug, Deserialize, Clone)]
pub struct EncryptionConfig {
    pub key: String,      // 32바이트 암호화 키 (base64 인코딩)
    pub nonce: String,    // 12바이트 nonce (base64 인코딩)
}

impl Default for EncryptionConfig {
    fn default() -> Self {
        Self {
            key: std::env::var("ENCRYPTION_KEY").unwrap_or_else(|_| "your-32-byte-secret-key-here".to_string()),
            nonce: std::env::var("ENCRYPTION_NONCE").unwrap_or_else(|_| "unique-nonce12".to_string()),
        }
    }
}

#[derive(Debug, Deserialize, Clone)]
pub struct HttpServerConfig {
    pub host: String,
    pub port: u16,
    pub cors_origins: Vec<String>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub timeout_seconds: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct AuthConfig {
    pub jwt_secret: String,
    pub access_token_expire: i64,  // 초 단위
    pub refresh_token_expire: i64, // 초 단위
    pub token_expiration_hours: i64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct MonitoringConfig {
    pub metrics_interval_seconds: u64,
    pub retention_days: i64,
    pub alert_thresholds: AlertThresholds,
}

#[derive(Debug, Deserialize, Clone)]
pub struct AlertThresholds {
    pub cpu_warning: f32,
    pub cpu_critical: f32,
    pub memory_warning: f32,
    pub memory_critical: f32,
    pub disk_warning: f32,
    pub disk_critical: f32,
}

impl Default for AuthConfig {
    fn default() -> Self {
        Self {
            jwt_secret: std::env::var("JWT_SECRET")
                .unwrap_or_else(|_| panic!("JWT_SECRET must be set")),
            access_token_expire: 900,     // 15분
            refresh_token_expire: 604800, // 7일
            token_expiration_hours: 24,   // 24시간
        }
    }
}

impl ServerConfig {
    pub fn with_defaults() -> Self {
        Self {
            server: HttpServerConfig {
                host: "127.0.0.1".to_string(),
                port: 8080,
                cors_origins: vec!["http://localhost:3000".to_string()],
            },
            database: DatabaseConfig {
                url: "postgres://localhost/myapp".to_string(),
                max_connections: 5,
                timeout_seconds: 30,
            },
            auth: AuthConfig::default(),
            monitoring: MonitoringConfig {
                metrics_interval_seconds: 60,
                retention_days: 30,
                alert_thresholds: AlertThresholds {
                    cpu_warning: 80.0,
                    cpu_critical: 90.0,
                    memory_warning: 80.0,
                    memory_critical: 90.0,
                    disk_warning: 80.0,
                    disk_critical: 90.0,
                },
            },
            encryption: EncryptionConfig::default(),
        }
    }
}