// server/src/db/repository.rs
use super::models::*;
use super::DbPool;
use anyhow::Result;
use crate::models::logs::{LogEntry, LogFilter, LogLevel, LogMetadata};
use chrono::{DateTime, Utc};
use sqlx::types::JsonValue;
use sqlx::{Row, QueryBuilder};
//use std::str::FromStr;

#[derive(Clone)]
pub struct Repository {
    pub(crate) pool: DbPool,
}

impl Repository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }

    pub async fn create_server(&self, server: Server) -> Result<Server> {
        let result = sqlx::query_as!(
            Server,
            r#"
            INSERT INTO servers 
            (id, name, hostname, ip_address, location, description, server_type, 
             is_online, last_seen_at, metadata, created_by, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7::text::server_type, $8, $9, $10, $11, $12, $13)
            RETURNING 
                id, name, hostname, ip_address, location,
                description,
                server_type as "server_type: ServerType",
                is_online,
                last_seen_at,
                metadata,
                created_by,
                created_at,
                updated_at
            "#,
            server.id,
            server.name,
            server.hostname,
            server.ip_address,
            server.location,
            server.description,
            server.server_type.to_string(),
            server.is_online,
            server.last_seen_at,
            server.metadata,
            server.created_by,
            server.created_at,
            server.updated_at,
        )
        .fetch_one(&self.pool)
        .await?;
    
        Ok(result)
    }

    pub async fn get_server(&self, id: &str) -> Result<Option<Server>> {
        let result = sqlx::query_as!(
            Server,
            r#"
            SELECT 
                id, name, hostname, ip_address, location,
                description,
                server_type as "server_type: ServerType",
                is_online,
                last_seen_at,
                metadata,
                created_by,
                created_at, updated_at
            FROM servers 
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(result)
    }

    pub async fn list_servers(&self) -> Result<Vec<Server>> {
        let results = sqlx::query_as!(
            Server,
            r#"
            SELECT 
                id, name, hostname, ip_address, location,
                description,
                server_type as "server_type: ServerType",
                is_online,
                last_seen_at,
                metadata,
                created_by,
                created_at, updated_at
            FROM servers 
            ORDER BY created_at DESC
            "#
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(results)
    }

    pub async fn delete_server(&self, id: &str) -> Result<()> {
        sqlx::query!(
            r#"
            DELETE FROM servers
            WHERE id = $1
            "#,
            id
        )
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn create_initial_metrics(&self, server_id: &str) -> Result<()> {
        let initial_snapshot = MetricsSnapshot {
            id: 0,  // Will be set by DB
            server_id: server_id.to_string(),
            cpu_usage: 0.0,
            memory_usage: 0.0,
            disk_usage: 0.0,
            network_rx: 0,  // Changed to 0 (i64)
            network_tx: 0,  // Changed to 0 (i64)
            processes: serde_json::json!([]),
            timestamp: Utc::now(),
        };
    
        self.save_metrics(initial_snapshot).await?;
        Ok(())
    }
    pub async fn save_metrics(&self, snapshot: MetricsSnapshot) -> Result<i64> {
        let result = sqlx::query!(
            r#"
            INSERT INTO metrics_snapshots 
            (server_id, cpu_usage, memory_usage, disk_usage, network_rx, network_tx, processes, timestamp)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id
            "#,
            snapshot.server_id,
            snapshot.cpu_usage,
            snapshot.memory_usage,
            snapshot.disk_usage,
            snapshot.network_rx,
            snapshot.network_tx,
            snapshot.processes as JsonValue,
            snapshot.timestamp
        )
        .fetch_one(&self.pool)
        .await?;
    
        Ok(result.id)
    }

    pub async fn get_server_metrics(
        &self,
        server_id: &str,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> Result<Vec<MetricsSnapshot>> {
        let results = sqlx::query_as!(
            MetricsSnapshot,
            r#"
            SELECT 
                id, server_id, cpu_usage, memory_usage, disk_usage,
                network_rx, network_tx, processes as "processes: JsonValue",
                timestamp
            FROM metrics_snapshots
            WHERE server_id = $1 AND timestamp BETWEEN $2 AND $3
            ORDER BY timestamp DESC
            "#,
            server_id,
            from,
            to
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(results)
    }

    pub async fn create_alert(&self, alert: Alert) -> Result<Alert> {
        let result = sqlx::query_as!(
            Alert,
            r#"
            INSERT INTO alerts 
            (server_id, alert_type, severity, message, created_at, acknowledged_at, acknowledged_by)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, server_id, alert_type, 
                      severity as "severity: AlertSeverity", 
                      message, created_at, acknowledged_at, acknowledged_by
            "#,
            alert.server_id,
            alert.alert_type,
            alert.severity as AlertSeverity,
            alert.message,
            alert.created_at,
            alert.acknowledged_at,
            alert.acknowledged_by
        )
        .fetch_one(&self.pool)
        .await?;
    
        Ok(result)
    }

    pub async fn get_unacknowledged_alerts(&self) -> Result<Vec<Alert>> {
        let results = sqlx::query_as!(
            Alert,
            r#"
            SELECT 
                id, server_id, alert_type,
                severity as "severity: AlertSeverity",
                message, created_at, acknowledged_at, acknowledged_by
            FROM alerts
            WHERE acknowledged_at IS NULL
            ORDER BY created_at DESC
            "#
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(results)
    }

    pub async fn create_user(&self, user: User) -> Result<User> {
        let result = sqlx::query_as!(
            User,
            r#"
            INSERT INTO users 
            (id, email, password_hash, name, role, provider, profile_image_url, created_at, updated_at, last_login_at)
            VALUES ($1, $2, $3, $4, $5::user_role, $6::auth_provider, $7, $8, $9, $10)
            RETURNING id, email, password_hash, name, 
                      role as "role: UserRole",
                      provider as "provider: AuthProvider",
                      profile_image_url, created_at, updated_at, last_login_at
            "#,
            user.id,
            user.email,
            user.password_hash,
            user.name,
            user.role as UserRole,
            user.provider as AuthProvider,
            user.profile_image_url,
            user.created_at,
            user.updated_at,
            user.last_login_at,
        )
        .fetch_one(&self.pool)
        .await?;
    
        Ok(result)
    }

    pub async fn update_user(&self, user: User) -> Result<User> {
        let result = sqlx::query_as!(
            User,
            r#"
            UPDATE users 
            SET 
                name = $1,
                profile_image_url = $2,
                last_login_at = $3,
                updated_at = $4
            WHERE id = $5
            RETURNING 
                id, email, password_hash, name,
                role as "role: UserRole",
                provider as "provider: AuthProvider",
                profile_image_url,
                created_at, updated_at, last_login_at
            "#,
            user.name,
            user.profile_image_url,
            user.last_login_at,
            user.updated_at,
            user.id
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }
    
    pub async fn get_user_by_email(&self, email: &str) -> Result<Option<User>> {
        let result = sqlx::query_as!(
            User,
            r#"
            SELECT 
                id, email, password_hash, name,
                role as "role: UserRole",
                provider as "provider: AuthProvider",
                profile_image_url, created_at, updated_at, last_login_at
            FROM users 
            WHERE email = $1
            "#,
            email
        )
        .fetch_optional(&self.pool)
        .await?;
    
        Ok(result)
    }

    pub async fn check_connection(&self) -> Result<()> {
        sqlx::query("SELECT 1")
            .execute(&self.pool)
            .await
            .map(|_| ())
            .map_err(Into::into)
    }


    pub async fn acknowledge_alert(&self, alert_id: i64) -> Result<()> {
        sqlx::query_as!(
            Alert,
            r#"
            UPDATE alerts
            SET acknowledged_at = $1, acknowledged_by = $2
            WHERE id = $3
            RETURNING id, server_id, alert_type, 
                      severity as "severity: AlertSeverity",
                      message, created_at, acknowledged_at, acknowledged_by
            "#,
            Utc::now(),
            Option::<String>::None,  // acknowledged_by
            alert_id
        )
        .fetch_one(&self.pool)
        .await?;
    
        Ok(())
    }

    pub async fn update_server_status(&self, id: &str, is_online: bool) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE servers
            SET is_online = $1, updated_at = $2
            WHERE id = $3
            "#,
            is_online,
            Utc::now(),
            id
        )
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_server_by_hostname(&self, hostname: &str) -> Result<Option<Server>> {
        let result = sqlx::query_as!(
            Server,
            r#"
            SELECT 
                id, name, hostname, ip_address, location,
                description,
                server_type as "server_type: ServerType",
                is_online,
                last_seen_at,
                metadata,
                created_by,
                created_at, updated_at
            FROM servers 
            WHERE hostname = $1
            "#,
            hostname
        )
        .fetch_optional(&self.pool)
        .await?;
    
        Ok(result)
    }

    pub async fn create_log(&self, log: LogEntry) -> Result<LogEntry> {
        let metadata_json = match &log.metadata.0 {
            Some(map) => serde_json::to_value(map).unwrap_or(JsonValue::Null),
            None => JsonValue::Null,
        };
    
        let result = sqlx::query!(
            r#"
            WITH inserted AS (
                INSERT INTO logs (
                    id, level, message, component, server_id, timestamp,
                    metadata, stack_trace, source_location, correlation_id
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                RETURNING 
                    id, 
                    level as "level: LogLevel", 
                    message, 
                    component, 
                    server_id,
                    timestamp, 
                    metadata as "metadata!: JsonValue",
                    stack_trace, 
                    source_location, 
                    correlation_id
            )
            SELECT 
                i.*,
                ts.tsv::text as message_tsv
            FROM inserted i
            CROSS JOIN LATERAL (
                SELECT to_tsvector('english', i.message) as tsv
            ) ts
            "#,
            log.id,
            log.level as LogLevel,
            log.message,
            log.component,
            log.server_id,
            log.timestamp,
            metadata_json,
            log.stack_trace,
            log.source_location,
            log.correlation_id
        )
        .fetch_one(&self.pool)
        .await?;
    
        Ok(LogEntry {
            id: result.id,
            level: result.level,
            message: result.message,
            component: result.component,
            server_id: result.server_id,
            timestamp: result.timestamp,
            metadata: LogMetadata::from(result.metadata),
            stack_trace: result.stack_trace,
            source_location: result.source_location,
            correlation_id: result.correlation_id,
            message_tsv: result.message_tsv,
        })
            }

    pub async fn get_log(&self, id: &str) -> Result<Option<LogEntry>> {
        sqlx::query_as!(
            LogEntry,
            r#"
            SELECT 
                id,
                level::text as "level!",
                message,
                component,
                server_id,
                timestamp,
                metadata as "metadata!: JsonValue",
                stack_trace,
                source_location,
                correlation_id,
                message_tsv::text as message_tsv
            FROM logs 
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(Into::into)
    }

    pub async fn get_logs(&self, filter: LogFilter) -> Result<Vec<LogEntry>> {
        let mut query = QueryBuilder::new(
            r#"
            SELECT 
                id, 
                level::text as level,
                message,
                component,
                server_id,
                timestamp,
                metadata,
                stack_trace,
                source_location,
                correlation_id,
                message_tsv::text as message_tsv
            FROM logs WHERE true
            "#
        );
        
        if let Some(levels) = filter.levels {
            query.push(" AND level = ANY(");
            let level_strings: Vec<String> = levels.into_iter()
                .map(|l| l.to_string())
                .collect();
            query.push_bind(level_strings);
            query.push("::log_level[])");
        }

        if let Some(from) = filter.from {
            query.push(" AND timestamp >= ");
            query.push_bind(from);
        }

        if let Some(to) = filter.to {
            query.push(" AND timestamp <= ");
            query.push_bind(to);
        }

        if let Some(server_id) = filter.server_id {
            query.push(" AND server_id = ");
            query.push_bind(server_id);
        }

        if let Some(component) = filter.component {
            query.push(" AND component = ");
            query.push_bind(component);
        }

        if let Some(search) = filter.search {
            query.push(" AND message_tsv @@ plainto_tsquery('english', ");
            query.push_bind(search);
            query.push(")");
        }

        query.push(" ORDER BY timestamp DESC");

        if let Some(limit) = filter.limit {
            query.push(" LIMIT ");
            query.push_bind(limit);
        }

        if let Some(offset) = filter.offset {
            query.push(" OFFSET ");
            query.push_bind(offset);
        }

        let sql = query.build();
        let rows = sql.fetch_all(&self.pool).await?;
    
        let logs = rows.iter().map(|row| LogEntry {
            id: row.get("id"),
            level: LogLevel::from(row.get::<String, _>("level")),
            message: row.get("message"),
            component: row.get("component"),
            server_id: row.get("server_id"),
            timestamp: row.get("timestamp"),
            metadata: LogMetadata::from(row.get::<JsonValue, _>("metadata")),
            stack_trace: row.get("stack_trace"),
            source_location: row.get("source_location"),
            correlation_id: row.get("correlation_id"),
            message_tsv: row.get("message_tsv"),
        }).collect();
    
        Ok(logs)
    }

    pub async fn delete_logs(&self, filter: LogFilter) -> Result<i64> {
        let mut query = QueryBuilder::new("DELETE FROM logs WHERE true");

        if let Some(from) = filter.from {
            query.push(" AND timestamp >= ");
            query.push_bind(from);
        }

        if let Some(to) = filter.to {
            query.push(" AND timestamp <= ");
            query.push_bind(to);
        }

        if let Some(server_id) = filter.server_id {
            query.push(" AND server_id = ");
            query.push_bind(server_id);
        }

        if let Some(component) = filter.component {
            query.push(" AND component = ");
            query.push_bind(component);
        }

        let result = query.build()
            .execute(&self.pool)
            .await?;

        Ok(result.rows_affected() as i64)
    }
}