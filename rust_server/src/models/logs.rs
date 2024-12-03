// src/models/logs.rs
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use std::collections::HashMap;
use sqlx::postgres::PgHasArrayType;
use sqlx::{Decode, Encode, Postgres, Type};
use sqlx::types::JsonValue;
use sqlx::postgres::PgArgumentBuffer;
use sqlx::encode::IsNull;
use std::str::FromStr;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "log_level")]
#[sqlx(rename_all = "lowercase")]
pub enum LogLevel {
    Debug,
    Info,
    Warning,
    Alert,
    Critical,
}

#[derive(Debug, Clone)]
pub struct ParseLogLevelError(String);

impl std::fmt::Display for LogLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LogLevel::Debug => write!(f, "debug"),
            LogLevel::Info => write!(f, "info"),
            LogLevel::Warning => write!(f, "warning"),
            LogLevel::Alert => write!(f, "alert"),
            LogLevel::Critical => write!(f, "critical"),
        }
    }
}

impl From<String> for LogLevel {
    fn from(s: String) -> Self {
        LogLevel::from_str(&s).unwrap_or(LogLevel::Info)
    }
}

impl FromStr for LogLevel {
    type Err = ParseLogLevelError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "debug" => Ok(LogLevel::Debug),
            "info" => Ok(LogLevel::Info),
            "warning" => Ok(LogLevel::Warning),
            "alert" => Ok(LogLevel::Alert),
            "critical" => Ok(LogLevel::Critical),
            _ => Err(ParseLogLevelError(format!("Invalid log level: {}", s))),
        }
    }
}

impl PgHasArrayType for LogLevel {
    fn array_type_info() -> sqlx::postgres::PgTypeInfo {
        sqlx::postgres::PgTypeInfo::with_name("_log_level")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogMetadata(pub Option<HashMap<String, JsonValue>>);

impl Type<Postgres> for LogMetadata {
    fn type_info() -> sqlx::postgres::PgTypeInfo {
        sqlx::postgres::PgTypeInfo::with_name("jsonb")
    }
}

impl<'r> Decode<'r, Postgres> for LogMetadata {
    fn decode(value: sqlx::postgres::PgValueRef<'r>) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let json = <JsonValue as Decode<'r, Postgres>>::decode(value)?;
        if json.is_null() {
            Ok(LogMetadata(None))
        } else {
            let map = serde_json::from_value(json)?;
            Ok(LogMetadata(Some(map)))
        }
    }
}

impl Encode<'_, Postgres> for LogMetadata {
    fn encode_by_ref(&self, buf: &mut PgArgumentBuffer) -> IsNull {
        match &self.0 {
            Some(map) => {
                let json = serde_json::to_value(map).unwrap_or(JsonValue::Null);
                <JsonValue as Encode<Postgres>>::encode_by_ref(&json, buf)
            }
            None => <JsonValue as Encode<Postgres>>::encode_by_ref(&JsonValue::Null, buf),
        }
    }
}

impl From<JsonValue> for LogMetadata {
    fn from(json: JsonValue) -> Self {
        if json.is_null() {
            LogMetadata(None)
        } else {
            LogMetadata(Some(serde_json::from_value(json).unwrap_or_default()))
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogEntry {
    pub id: String,
    pub level: LogLevel,
    pub message: String,
    pub component: String,
    pub server_id: Option<String>,
    pub timestamp: DateTime<Utc>,
    pub metadata: LogMetadata,
    pub stack_trace: Option<String>,
    pub source_location: Option<String>,
    pub correlation_id: Option<String>,
    pub message_tsv: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogFilter {
    pub levels: Option<Vec<LogLevel>>,
    pub from: Option<DateTime<Utc>>,
    pub to: Option<DateTime<Utc>>,
    pub server_id: Option<String>,
    pub component: Option<String>,
    pub search: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

impl LogEntry {
    pub fn new(
        level: LogLevel,
        message: String,
        component: String,
        server_id: Option<String>,
    ) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            level,
            message,
            component,
            server_id,
            timestamp: Utc::now(),
            metadata: LogMetadata(None),
            stack_trace: None,
            source_location: None,
            correlation_id: None,
            message_tsv: None,
        }
    }

    pub fn with_metadata(mut self, metadata: HashMap<String, serde_json::Value>) -> Self {
        self.metadata = LogMetadata(Some(metadata));
        self
    }

    pub fn with_stack_trace(mut self, stack_trace: String) -> Self {
        self.stack_trace = Some(stack_trace);
        self
    }

    pub fn with_source_location(mut self, source_location: String) -> Self {
        self.source_location = Some(source_location);
        self
    }

    pub fn with_correlation_id(mut self, correlation_id: String) -> Self {
        self.correlation_id = Some(correlation_id);
        self
    }
}

impl LogFilter {
    pub fn new() -> Self {
        Self {
            levels: None,
            from: None,
            to: None,
            server_id: None,
            component: None,
            search: None,
            limit: None,
            offset: None,
        }
    }

    pub fn with_levels(mut self, levels: Vec<LogLevel>) -> Self {
        self.levels = Some(levels);
        self
    }

    pub fn with_timerange(mut self, from: DateTime<Utc>, to: DateTime<Utc>) -> Self {
        self.from = Some(from);
        self.to = Some(to);
        self
    }

    pub fn with_server_id(mut self, server_id: String) -> Self {
        self.server_id = Some(server_id);
        self
    }

    pub fn with_component(mut self, component: String) -> Self {
        self.component = Some(component);
        self
    }

    pub fn with_search(mut self, search: String) -> Self {
        self.search = Some(search);
        self
    }

    pub fn with_pagination(mut self, limit: i64, offset: i64) -> Self {
        self.limit = Some(limit);
        self.offset = Some(offset);
        self
    }
}