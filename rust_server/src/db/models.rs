// server/src/db/models.rs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::JsonValue;
use std::fmt::Display;
use std::str::FromStr;
use uuid::Uuid;

// Common traits implementation macro
macro_rules! impl_common_traits {
    ($name:ident, { $($variant:ident => $str:expr),* $(,)* }) => {
        impl $name {
            pub fn as_ref(&self) -> &str {
                match self {
                    $(Self::$variant => $str),*
                }
            }
        }

        impl Display for $name {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                f.write_str(self.as_ref())
            }
        }

        impl FromStr for $name {
            type Err = String;
            
            fn from_str(s: &str) -> Result<Self, Self::Err> {
                match s.to_lowercase().as_str() {
                    $($str => Ok(Self::$variant),)*
                    _ => Err(format!("Invalid {} value: {}", stringify!($name), s))
                }
            }
        }
    };
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "server_type")]
#[sqlx(rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum ServerType {
    Linux,
    MacOS,
    Windows
}

impl Default for ServerType {
    fn default() -> Self {
        ServerType::Linux
    }
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "server_category")]
#[sqlx(rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum ServerCategory {
    Physical,
    Virtual,
    Container
}

impl Default for ServerCategory {
    fn default() -> Self {
        ServerCategory::Physical
    }
}

// Common traits 구현
impl_common_traits!(ServerType, {
    Linux => "linux",
    MacOS => "macos",
    Windows => "windows"
});

impl_common_traits!(ServerCategory, {
    Physical => "physical",
    Virtual => "virtual",
    Container => "container"
});


#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Server {
    pub id: String,
    pub name: String,
    pub hostname: String,
    pub ip_address: Option<String>, 
    pub port: i32,
    pub username: String,
    pub encrypted_password: String,
    pub location: Option<String>,   
    pub description: Option<String>,
    #[sqlx(rename = "server_type")]
    pub server_type: ServerType,
    pub category: ServerCategory,
    pub is_online: bool,
    pub last_seen_at: Option<DateTime<Utc>>,
    pub metadata: Option<JsonValue>,
    pub created_by: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Default for Server {
    fn default() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: String::new(),
            hostname: String::new(),
            ip_address: None, 
            port: 0,
            username: String::new(),
            encrypted_password: String::new(),
            location: Some("Unknown".to_string()), 
            description: None,
            server_type: ServerType::default(),
            category: ServerCategory::default(),
            is_online: false,
            last_seen_at: None,
            metadata: Some(serde_json::json!({})),
            created_by: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }    
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "alert_severity")]
#[sqlx(rename_all = "lowercase")]
pub enum AlertSeverity {
    Info,
    Warning,
    Critical,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "user_role")]
#[sqlx(rename_all = "lowercase")]
pub enum UserRole {
    Admin,
    User,
    Viewer,
}

// 다른 enum들에 대한 common traits 구현
impl_common_traits!(AlertSeverity, {
    Info => "info",
    Warning => "warning",
    Critical => "critical"
});

impl_common_traits!(UserRole, {
    Admin => "admin",
    User => "user",
    Viewer => "viewer"
});

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow, Clone)]
pub struct MetricsSnapshot {
    pub id: i64,
    pub server_id: String,
    pub cpu_usage: f64,
    pub memory_usage: f64,
    pub disk_usage: f64,
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
    #[sqlx(rename = "severity")]
    pub severity: AlertSeverity,
    pub message: String,
    pub created_at: DateTime<Utc>,
    pub acknowledged_at: Option<DateTime<Utc>>,
    pub acknowledged_by: Option<String>,
}


#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
#[sqlx(type_name = "auth_provider")]
#[sqlx(rename_all = "lowercase")]
pub enum AuthProvider {
    Email,
    Google,
    Apple,
    Kakao,
    Facebook,
}

impl_common_traits!(AuthProvider, {
    Email => "email",
    Google => "google",
    Apple => "apple",
    Kakao => "kakao",
    Facebook => "facebook"
});

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: String,
    pub email: String,
    pub password_hash: Option<String>,  // null 허용 (소셜 로그인의 경우)
    pub name: String,
    #[sqlx(rename = "role")]
    pub role: UserRole,
    #[sqlx(rename = "provider")]
    pub provider: AuthProvider,
    pub profile_image_url: Option<String>,  // 프로필 이미지 URL
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub last_login_at: Option<DateTime<Utc>>,
}

impl Default for User {
    fn default() -> Self {
        Self {
            id: String::new(),
            email: String::new(),
            password_hash: None,
            name: String::new(),
            role: UserRole::User,  // 기본 역할은 User
            provider: AuthProvider::Email,  // 기본 provider는 Email
            profile_image_url: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
            last_login_at: None,
        }
    }
}

#[derive(Debug, sqlx::FromRow)]
pub struct RefreshToken {
    pub id: String,
    pub user_id: String,
    pub token: String,
    pub expires_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow)]
pub struct UserSession {
    pub id: String,
    pub user_id: String,
    pub device_info: Option<String>,
    pub last_activity: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}