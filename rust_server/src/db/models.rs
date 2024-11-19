// server/src/db/models.rs
<<<<<<< HEAD
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
=======

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::JsonValue;
//use sqlx::Type;
>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Server {
    pub id: String,
    pub name: String,
    pub hostname: String,
    pub ip_address: String,
    pub location: String,
<<<<<<< HEAD
    pub server_type: ServerType,  // String에서 ServerType으로 변경
=======
    pub server_type: String,
>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d
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
<<<<<<< HEAD
    pub severity: AlertSeverity,  // String에서 AlertSeverity로 변경 // 타입을 sql 파일에 맞춰야함
    pub message: String,
    pub created_at: DateTime<Utc>,
    pub acknowledged_at: Option<DateTime<Utc>>,
    pub acknowledged_by: Option<String>,  // 누락된 필드 추가
=======
    pub severity: String,
    pub message: String,
    pub created_at: DateTime<Utc>,
    pub acknowledged_at: Option<DateTime<Utc>>,
>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: String,
    pub email: String,
    pub password_hash: String,
    pub name: String,
<<<<<<< HEAD
    pub role: UserRole,  // String에서 UserRole로 변경
=======
    pub role: String,
>>>>>>> d18e561ecf6f553bddd2ea81a6fbdc848ce1417d
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}