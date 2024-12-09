# 시스템 메트릭 수집

## 수집 항목

### 1. CPU 메트릭
- 전체 CPU 사용률 (%)
- Top 10 프로세스별 CPU 사용률

### 2. 메모리 메트릭
- 전체 메모리 사용량 (%)
- 사용 중인 메모리 (bytes)
- 전체 메모리 크기 (bytes)
- Top 10 프로세스별 메모리 사용량

### 3. 디스크 메트릭
- 전체 디스크 사용률 (%)
- 사용 중인 공간 (bytes)
- 전체 디스크 공간 (bytes)

### 4. 네트워크 메트릭
- 수신 트래픽 (bytes/s)
- 송신 트래픽 (bytes/s)

## 수집 주기

- **실시간 수집**: 1초 간격
- **데이터베이스 저장**: 5초 간격
- **데이터 보존 기간**: 30일

## 임계값 설정

```rust
AlertThresholds {
    cpu_warning: 80.0,    // CPU 경고 임계값 (%)
    cpu_critical: 90.0,   // CPU 위험 임계값 (%)
    memory_warning: 80.0, // 메모리 경고 임계값 (%)
    memory_critical: 90.0 // 메모리 위험 임계값 (%)
    disk_warning: 80.0,   // 디스크 경고 임계값 (%)
    disk_critical: 90.0   // 디스크 위험 임계값 (%)
}
```

## 메트릭 저장소

### TimescaleDB 스키마
```sql
CREATE TABLE metrics_snapshots (
    id BIGSERIAL PRIMARY KEY,
    server_id VARCHAR(36) REFERENCES servers(id),
    cpu_usage DOUBLE PRECISION,
    memory_usage DOUBLE PRECISION,
    disk_usage DOUBLE PRECISION,
    network_rx BIGINT,
    network_tx BIGINT,
    processes JSONB,
    timestamp TIMESTAMPTZ
);
```

### 데이터 압축
- 7일 이상 된 데이터에 대해 압축 적용
- 시간별/일별 집계 데이터 생성

## 메트릭 조회

### 1. 실시간 메트릭
- WebSocket을 통한 실시간 스트리밍
- 1초 간격 업데이트

### 2. 히스토리 데이터
- REST API를 통한 조회
- 기간별 집계 데이터 제공
- 커스텀 시간 범위 지원