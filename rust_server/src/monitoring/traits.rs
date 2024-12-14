// src/monitoring/traits.rs
use crate::models::metrics::{ServerMetrics, ProcessMetrics};

#[cfg_attr(test, mockall::automock)]
pub trait MonitoringServiceTrait {
    async fn get_current_metrics(&self) -> Option<ServerMetrics>;
    async fn get_server_metrics(&self, server_id: &str) -> Option<ServerMetrics>;
    async fn get_server_processes(&self, server_id: &str) -> Option<Vec<ProcessMetrics>>;
}

// MonitoringService에 대한 trait
impl MonitoringServiceTrait for super::MonitoringService {
    async fn get_current_metrics(&self) -> Option<ServerMetrics> {
        self.get_current_metrics().await
    }

    async fn get_server_metrics(&self, server_id: &str) -> Option<ServerMetrics> {
        self.get_server_metrics(server_id).await
    }

    async fn get_server_processes(&self, server_id: &str) -> Option<Vec<ProcessMetrics>> {
        self.get_server_processes(server_id).await
    }
}