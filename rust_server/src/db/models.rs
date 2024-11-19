// server/src/db/models.rs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::JsonValue;

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "server_type", rename_all = "lowercase")]
pub enum ServerType {
    Physical,
    Virtual,
    Container
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "alert_severity", rename_all = "lowercase")]
pub enum AlertSeverity {
    Info,
    Warning,
    Critical
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "user_role", rename_all = "lowercase")]
pub enum UserRole {
    Admin,
    User,
    Viewer
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Server {
    pub id: String,
    pub name: String,
    pub hostname: String,
    pub ip_address: String,
    pub location: String,
    pub server_type: ServerType,  // String에서 ServerType으로 변경
    pub is_online: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct MetricsSnapshot {
    pub id: i64,
    pub server_id: String,
    pub cpu_usage: f32,
    pub memory_usage: f32,
    pub disk_usage: f32,
    pub network_rx: i64,
    pub network_tx: i64,
    pub processes: JsonValue,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Alert {
    pub id: i64,
    pub server_id: String,
    pub alert_type: String,
    pub severity: AlertSeverity,  // String에서 AlertSeverity로 변경 // 타입을 sql 파일에 맞춰야함
    pub message: String,
    pub created_at: DateTime<Utc>,
    pub acknowledged_at: Option<DateTime<Utc>>,
    pub acknowledged_by: Option<String>,  // 누락된 필드 추가
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: String,
    pub email: String,
    pub password_hash: String,
    pub name: String,
    pub role: UserRole,  // String에서 UserRole로 변경
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}