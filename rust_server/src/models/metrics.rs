// src/models/metrics.rs
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};


#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ServerMetrics {
    pub cpu_usage: f32,
    pub memory_usage: f32,
    pub disk_usage: f32,
    pub network_rx: u64,
    pub network_tx: u64,
    pub timestamp: DateTime<Utc>,
    #[serde(default)]
    pub processes: Vec<ProcessMetrics>,
}

impl ServerMetrics {
    pub fn new(
        cpu_usage: f32,
        memory_usage: f32,
        disk_usage: f32,
        network_rx: u64,
        network_tx: u64,
        processes: Vec<ProcessMetrics>,
    ) -> Self {
        Self {
            cpu_usage,
            memory_usage,
            disk_usage,
            network_rx,
            network_tx,
            timestamp: Utc::now(),
            processes,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.cpu_usage == 0.0 && self.memory_usage == 0.0 && self.disk_usage == 0.0
    }

    pub fn update_timestamp(&mut self) {
        self.timestamp = Utc::now();
    }

    pub fn total_network_usage(&self) -> u64 {
        self.network_rx + self.network_tx
    }
}
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessMetrics {
    pub pid: u32,
    pub name: String,
    pub cpu_usage: f32,
    pub memory_usage: u64,
}

#[allow(dead_code)]
impl ProcessMetrics {
    pub fn new(pid: u32, name: String, cpu_usage: f32, memory_usage: u64) -> Self {
        Self {
            pid,
            name,
            cpu_usage,
            memory_usage,
        }
    }

    // 프로세스가 높은 CPU 사용률을 보이는지 확인
    pub fn is_high_cpu(&self) -> bool {
        self.cpu_usage > 80.0
    }

    // 프로세스가 높은 메모리 사용률을 보이는지 확인
    pub fn is_high_memory(&self, total_memory: u64) -> bool {
        let memory_percentage = (self.memory_usage as f64 / total_memory as f64) * 100.0;
        memory_percentage > 80.0
    }
}

// 테스트 코드 추가
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_server_metrics_new() {
        let processes = vec![
            ProcessMetrics::new(1, "test1".to_string(), 10.0, 1000),
            ProcessMetrics::new(2, "test2".to_string(), 20.0, 2000),
        ];

        let metrics = ServerMetrics::new(
            50.0,
            60.0,
            70.0,
            1000,
            2000,
            processes,
        );

        assert_eq!(metrics.cpu_usage, 50.0);
        assert_eq!(metrics.memory_usage, 60.0);
        assert_eq!(metrics.disk_usage, 70.0);
        assert_eq!(metrics.network_rx, 1000);
        assert_eq!(metrics.network_tx, 2000);
        assert_eq!(metrics.processes.len(), 2);
    }

    #[test]
    fn test_process_metrics() {
        let process = ProcessMetrics::new(1, "test".to_string(), 85.0, 1000);
        assert!(process.is_high_cpu());
        assert!(process.is_high_memory(1000)); // 100% 사용
        
        let process_low = ProcessMetrics::new(2, "test2".to_string(), 20.0, 100);
        assert!(!process_low.is_high_cpu());
        assert!(!process_low.is_high_memory(1000)); // 10% 사용
    }
}