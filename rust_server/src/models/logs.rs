// src/models/logs.rs
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use std::collections::HashMap;
use sqlx::postgres::PgHasArrayType;
use sqlx::types::JsonValue;
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

impl std::fmt::Display for LogLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let level = match self {
            LogLevel::Debug => "debug",
            LogLevel::Info => "info",
            LogLevel::Warning => "warning",
            LogLevel::Alert => "alert",
            LogLevel::Critical => "critical",
        };
        write!(f, "{}", level)
    }
}

#[derive(Debug, Clone)]
pub struct ParseLogLevelError {
    pub input: String,
    pub message: String,
}

impl std::fmt::Display for ParseLogLevelError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Invalid log level '{}': {}", self.input, self.message)
    }
}

impl std::error::Error for ParseLogLevelError {}

impl FromStr for LogLevel {
    type Err = ParseLogLevelError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "debug" => Ok(LogLevel::Debug),
            "info" => Ok(LogLevel::Info),
            "warning" => Ok(LogLevel::Warning),
            "alert" => Ok(LogLevel::Alert),
            "critical" => Ok(LogLevel::Critical),
            _ => Err(ParseLogLevelError {
                input: s.to_string(),
                message: "Expected one of: debug, info, warning, alert, critical".to_string(),
            }),
        }
    }
}

impl PgHasArrayType for LogLevel {
    fn array_type_info() -> sqlx::postgres::PgTypeInfo {
        sqlx::postgres::PgTypeInfo::with_name("_log_level")
    }
}

#[derive(Debug, Serialize, Deserialize, Default)]  
pub struct LogMetadata {
    pub context: Option<String>,
    pub details: Option<JsonValue>,
}

impl From<JsonValue> for LogMetadata {
    fn from(json: JsonValue) -> Self {
        if json.is_null() {
            return Self::default();
        }

        match json {
            JsonValue::Object(map) => LogMetadata {
                context: map.get("context").and_then(|v| v.as_str()).map(String::from),
                details: Some(JsonValue::Object(map)),
            },
            _ => LogMetadata {
                context: None,
                details: Some(json),
            },
        }
    }
}

impl From<Option<JsonValue>> for LogMetadata {
    fn from(json_opt: Option<JsonValue>) -> Self {
        match json_opt {
            Some(json) => {
                if json.is_null() {
                    Self::default()
                } else {
                    match json {
                        JsonValue::Object(map) => LogMetadata {
                            context: map.get("context").and_then(|v| v.as_str()).map(String::from),
                            details: Some(JsonValue::Object(map)),
                        },
                        _ => LogMetadata {
                            context: None,
                            details: Some(json),
                        },
                    }
                }
            },
            None => Self::default(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateLogRequest {
    pub level: LogLevel,
    pub message: String,
    pub component: String,
    pub server_id: Option<String>,
    #[serde(default)]
    pub metadata: Option<HashMap<String, JsonValue>>,
    pub stack_trace: Option<String>,
    pub source_location: Option<String>,
}


#[derive(Debug, Serialize, Deserialize)]
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
            metadata: LogMetadata::default(),  // 수정된 부분
            stack_trace: None,
            source_location: None,
            correlation_id: None,
        }
    }

    pub fn with_metadata(mut self, metadata: HashMap<String, serde_json::Value>) -> Self {
        self.metadata = LogMetadata {
            context: None,
            details: Some(serde_json::Value::Object(
                metadata.into_iter().collect()
            )),
        };
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