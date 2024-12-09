// src/monitoring/mod.rs
use std::sync::Arc;
use tokio::sync::RwLock;
use crate::db::repository::Repository;
use crate::models::metrics::{ServerMetrics, ProcessMetrics};
use std::collections::HashMap;
use sysinfo::{System, SystemExt, ProcessExt, CpuExt, DiskExt, NetworkExt, NetworksExt, PidExt};
use crate::db::models::MetricsSnapshot;

pub mod collector;

#[derive(Clone)]
pub struct MetricsCollector {
    system: Arc<RwLock<System>>,
    metrics: Arc<RwLock<Option<ServerMetrics>>>,
}

impl MetricsCollector {
    pub fn new() -> Self {
        Self {
            system: Arc::new(RwLock::new(System::new_all())),
            metrics: Arc::new(RwLock::new(None)),
        }
    }

    pub async fn start_collection(&self) {
        let system = self.system.clone();
        let metrics = self.metrics.clone();

        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(1));
            
            loop {
                interval.tick().await;
                let mut sys = system.write().await;
                sys.refresh_all();

                let processes = collect_process_metrics(&sys);
                let current_metrics = ServerMetrics::new(
                    sys.global_cpu_info().cpu_usage(),
                    (sys.used_memory() as f32 / sys.total_memory() as f32) * 100.0,
                    calculate_disk_usage(&sys),
                    sys.networks().iter().map(|(_, data)| data.received()).sum(),
                    sys.networks().iter().map(|(_, data)| data.transmitted()).sum(),
                    processes,
                );

                *metrics.write().await = Some(current_metrics);
            }
        });
    }

    pub async fn get_current_metrics(&self) -> Option<ServerMetrics> {
        self.metrics.read().await.clone()
    }
}

#[derive(Clone)]
pub struct MonitoringService {
    repo: Repository,
    collectors: Arc<RwLock<HashMap<String, Arc<MetricsCollector>>>>,
}


impl MonitoringService {
    pub fn new(repo_data: actix_web::web::Data<Repository>) -> Self {
        Self {
            repo: repo_data.get_ref().clone(),
            collectors: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn start_monitoring(&self, server_id: &str) {
        let collector = Arc::new(MetricsCollector::new());
        
        // 서버 존재 여부만 확인하고 변수는 사용하지 않으므로 _로 시작
        if let Ok(Some(_server)) = self.repo.get_server(server_id).await {
            // 기존 컬렉터가 있다면 제거
            self.collectors.write().await.remove(server_id);
            
            // 새 컬렉터 시작
            collector.start_collection().await;
            
            // 서버 상태 업데이트
            let _ = self.repo.update_server_status(server_id, true).await;
            
            // 메트릭 저장을 위한 백그라운드 태스크 시작
            let repo = self.repo.clone();
            let collector_clone = collector.clone();
            let server_id = server_id.to_string();  // 먼저 String으로 변환
            
            // 클로저에서 사용할 server_id 복제
            let server_id_clone = server_id.clone();
            
            tokio::spawn(async move {
                let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(5));
                
                loop {
                    interval.tick().await;
                    if let Some(metrics) = collector_clone.get_current_metrics().await {
                        let snapshot = MetricsSnapshot {
                            id: 0,
                            server_id: server_id_clone.clone(), // 복제된 server_id 사용
                            cpu_usage: metrics.cpu_usage as f64,
                            memory_usage: metrics.memory_usage as f64,
                            disk_usage: metrics.disk_usage as f64,
                            network_rx: metrics.network_rx as i64,
                            network_tx: metrics.network_tx as i64,
                            processes: serde_json::to_value(&metrics.processes).unwrap_or_default(),
                            timestamp: chrono::Utc::now(),
                        };
                        
                        if let Err(e) = repo.save_metrics(snapshot).await {
                            eprintln!("Failed to save metrics: {}", e);
                        }
                    }
                }
            });
            
            // 컬렉터 저장 - 원본 server_id 사용
            self.collectors.write().await.insert(server_id, collector);
        }
    }
    
    // 글로벌 메트릭스 조회
    pub async fn get_current_metrics(&self) -> Option<ServerMetrics> {
        // 모든 컬렉터의 첫 번째 메트릭스 반환
        if let Some(collector) = self.collectors.read().await.values().next() {
            collector.get_current_metrics().await
        } else {
            None
        }
    }

    // 특정 서버의 메트릭스 조회
    pub async fn get_server_metrics(&self, server_id: &str) -> Option<ServerMetrics> {
        if let Some(collector) = self.collectors.read().await.get(server_id) {
            collector.get_current_metrics().await
        } else {
            // 컬렉터가 없다면 시작
            self.start_monitoring(server_id).await;
            None
        }
    }

    // 특정 서버의 프로세스 정보 조회
    pub async fn get_server_processes(&self, server_id: &str) -> Option<Vec<ProcessMetrics>> {
        if let Some(collector) = self.collectors.read().await.get(server_id) {
            collector.get_current_metrics().await.map(|m| m.processes)
        } else {
            None
        }
    }

    pub async fn stop_monitoring(&self, server_id: &str) {
        if let Some(_) = self.collectors.write().await.remove(server_id) {
            let _ = self.repo.update_server_status(server_id, false).await;
        }
    }
}

fn calculate_disk_usage(system: &System) -> f32 {
    let disks = system.disks();
    if disks.is_empty() {
        return 0.0;
    }

    let total: u64 = disks.iter().map(|disk| disk.total_space()).sum();
    let used: u64 = disks.iter().map(|disk| disk.total_space() - disk.available_space()).sum();

    (used as f32 / total as f32) * 100.0
}

fn collect_process_metrics(system: &System) -> Vec<ProcessMetrics> {
    let mut processes: Vec<ProcessMetrics> = system
        .processes()
        .iter()
        .map(|(pid, process)| ProcessMetrics::new(
            pid.as_u32(),
            process.name().to_string(),
            process.cpu_usage(),
            process.memory(),
        ))
        .collect();

    processes.sort_by(|a, b| b.cpu_usage.partial_cmp(&a.cpu_usage).unwrap());
    processes.truncate(10);
    
    processes
}