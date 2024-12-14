// tests/monitoring/collector.rs
use rust_server::monitoring::collector::MetricsCollector;
use tokio::time::{sleep, Duration};

#[tokio::test]
async fn test_metrics_collector_initialization() {
    let collector = MetricsCollector::new();
    assert!(collector.get_current_metrics().await.is_none());
}

#[tokio::test]
async fn test_metrics_collection() {
    let collector = MetricsCollector::new();
    collector.start_collection().await;

    // Wait for first collection
    sleep(Duration::from_secs(2)).await;

    let metrics = collector.get_current_metrics().await;
    assert!(metrics.is_some());

    let metrics = metrics.unwrap();
    assert!(metrics.cpu_usage >= 0.0 && metrics.cpu_usage <= 100.0);
    assert!(metrics.memory_usage >= 0.0 && metrics.memory_usage <= 100.0);
    assert!(metrics.disk_usage >= 0.0 && metrics.disk_usage <= 100.0);
    assert!(metrics.network_rx >= 0);
    assert!(metrics.network_tx >= 0);
    assert!(!metrics.processes.is_empty());
}

#[tokio::test]
async fn test_process_collection() {
    let collector = MetricsCollector::new();
    collector.start_collection().await;

    sleep(Duration::from_secs(2)).await;

    let metrics = collector.get_current_metrics().await.unwrap();
    let processes = metrics.processes;

    assert!(!processes.is_empty());
    assert!(processes.len() <= 10); // Should only collect top 10 processes

    for process in processes {
        assert!(process.pid > 0);
        assert!(!process.name.is_empty());
        assert!(process.cpu_usage >= 0.0);
        assert!(process.memory_usage > 0);
    }
}

#[tokio::test]
async fn test_metrics_updates() {
    let collector = MetricsCollector::new();
    collector.start_collection().await;

    // Get initial metrics
    sleep(Duration::from_secs(1)).await;
    let initial_metrics = collector.get_current_metrics().await.unwrap();

    // Wait for update
    sleep(Duration::from_secs(2)).await;
    let updated_metrics = collector.get_current_metrics().await.unwrap();

    // Metrics should be different after update
    assert_ne!(initial_metrics.cpu_usage, updated_metrics.cpu_usage);
    assert_ne!(initial_metrics.network_rx, updated_metrics.network_rx);
    assert_ne!(initial_metrics.network_tx, updated_metrics.network_tx);
}

#[tokio::test]
async fn test_disk_usage_calculation() {
    let collector = MetricsCollector::new();
    collector.start_collection().await;

    sleep(Duration::from_secs(1)).await;
    let metrics = collector.get_current_metrics().await.unwrap();

    assert!(metrics.disk_usage >= 0.0);
    assert!(metrics.disk_usage <= 100.0);
}