// server/src/db/repository.rs
use chrono::{DateTime, Utc};
use sqlx::types::JsonValue;
use super::models::*;
use super::DbPool;
use anyhow::Result;

#[derive(Clone)]
pub struct Repository {
    pool: DbPool,
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
            (id, name, hostname, ip_address, location, server_type, is_online, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6::text::server_type, $7, $8, $9)
            RETURNING 
                id, name, hostname, ip_address, location,
                server_type as "server_type: ServerType", 
                is_online, created_at, updated_at
            "#,
            server.id,
            server.name,
            server.hostname,
            server.ip_address,
            server.location,
            server.server_type.to_string(),
            server.is_online,
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
                server_type as "server_type: ServerType",
                is_online, created_at, updated_at
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
                server_type as "server_type: ServerType",
                is_online, created_at, updated_at
            FROM servers 
            ORDER BY created_at DESC
            "#
        )
        .fetch_all(&self.pool)
        .await?;
    
        Ok(results)
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
            (id, email, password_hash, name, role, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, email, password_hash, name, 
                      role as "role: UserRole",
                      created_at, updated_at
            "#,
            user.id,
            user.email,
            user.password_hash,
            user.name,
            user.role as UserRole,
            user.created_at,
            user.updated_at
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
                created_at, updated_at
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
}