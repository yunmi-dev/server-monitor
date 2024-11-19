// src/monitoring/service.rs
use std::sync::Arc;
use tokio::sync::RwLock;
use sysinfo::{System, SystemExt, CpuExt, ProcessExt};
use crate::db::{models::MetricsSnapshot, repository::Repository};
use chrono::Utc;
use serde_json::json;

#[derive(Clone)]
pub struct MonitoringService {
    repository: Arc<Repository>,
    system: Arc<RwLock<System>>,
}

impl MonitoringService {
    pub fn new(repository: Arc<Repository>) -> Self {
        let mut system = System::new_all();
        system.refresh_all();
        
        Self {
            repository,
            system: Arc::new(RwLock::new(system)),
        }
    }

    pub async fn collect_metrics(&self, server_id: &str) -> anyhow::Result<MetricsSnapshot> {
        let mut system = self.system.write().await;
        system.refresh_all();

        let cpu_usage = system.global_cpu_info().cpu_usage();
        let total_memory = system.total_memory();
        let used_memory = system.used_memory();
        let memory_usage = (used_memory as f32 / total_memory as f32) * 100.0;
        
        // Collect process information
        let processes: Vec<serde_json::Value> = system.processes().iter()
        .take(10)
        .map(|(pid, process)| {
            json!({
                "pid": pid.to_string(),
                "name": process.name(),
                "cpu_usage": process.cpu_usage(),
                "memory_usage": process.memory()
            })
        })
        .collect();
    
        let snapshot = MetricsSnapshot {
            id: 0, // Will be set by database
            server_id: server_id.to_string(),
            cpu_usage,
            memory_usage,
            disk_usage: 0.0, // Implement disk usage collection
            network_rx: 0,    // Implement network metrics
            network_tx: 0,
            processes: json!(processes),
            timestamp: Utc::now(),
        };

        // Save metrics to database
        self.repository.save_metrics(snapshot.clone()).await?;

        Ok(snapshot)
    }

    pub async fn start_monitoring(&self, server_id: String) -> anyhow::Result<()> {
        let service = self.clone();
        
        tokio::spawn(async move {
            loop {
                if let Err(e) = service.collect_metrics(&server_id).await {
                    log::error!("Failed to collect metrics: {}", e);
                }
                tokio::time::sleep(std::time::Duration::from_secs(60)).await;
            }
        });

        Ok(())
    }
}