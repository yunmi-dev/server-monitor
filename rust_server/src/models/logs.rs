// src/models/logs.rs
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(rename_all = "snake_case")]
pub enum LogLevel {
    Debug,
    Info,
    Warning,
    Error,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogEntry {
    pub id: String,
    pub level: LogLevel,
    pub message: String,
    pub component: String,
    pub server_id: Option<String>,
    pub timestamp: DateTime<Utc>,
    pub metadata: Option<HashMap<String, serde_json::Value>>,
    pub stack_trace: Option<String>,
    pub source_location: Option<String>,
    pub correlation_id: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
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
            metadata: None,
            stack_trace: None,
            source_location: None,
            correlation_id: None,
        }
    }
}