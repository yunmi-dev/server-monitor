// server/src/db/models.rs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::JsonValue;
use std::str::FromStr;
use std::fmt::Display;

macro_rules! implement_enum {
    ($name:ident { $($variant:ident => $str:expr),* $(,)* }) => {
        #[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, PartialEq)]
        #[sqlx(rename_all = "lowercase")]
        pub enum $name {
            $($variant),*
        }

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

        impl From<&str> for $name {
            fn from(s: &str) -> Self {
                match s.to_lowercase().as_str() {
                    $($str => Self::$variant,)*
                    _ => panic!("Invalid {} value: {}", stringify!($name), s)
                }
            }
        }

        impl From<String> for $name {
            fn from(s: String) -> Self {
                Self::from(s.as_str())
            }
        }
    };
}

// Enum definitions
implement_enum!(ServerType {
    Physical => "physical",
    Virtual => "virtual",
    Container => "container"
});

implement_enum!(AlertSeverity {
    Info => "info",
    Warning => "warning",
    Critical => "critical"
});

implement_enum!(UserRole {
    Admin => "admin",
    User => "user",
    Viewer => "viewer"
});


#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Server {
    pub id: String,
    pub name: String,
    pub hostname: String,
    pub ip_address: String,
    pub location: String,
    pub server_type: ServerType,
    pub is_online: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

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
    pub severity: AlertSeverity,
    pub message: String,
    pub created_at: DateTime<Utc>,
    pub acknowledged_at: Option<DateTime<Utc>>,
    pub acknowledged_by: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: String,
    pub email: String,
    pub password_hash: String,
    pub name: String,
    pub role: UserRole,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}