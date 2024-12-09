# 데이터베이스 아키텍처

## 데이터베이스 스키마

### Users 테이블
```sql
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    active BOOLEAN NOT NULL DEFAULT true,
    provider auth_provider NOT NULL DEFAULT 'email',
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Servers 테이블
```sql
CREATE TABLE servers (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    hostname VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    port INTEGER NOT NULL,
    username VARCHAR(255) NOT NULL,
    encrypted_password TEXT NOT NULL,
    server_type server_type NOT NULL DEFAULT 'linux',
    server_category server_category NOT NULL DEFAULT 'physical',
    is_online BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Metrics 테이블 (TimescaleDB Hypertable)
```sql
CREATE TABLE metrics_snapshots (
    id BIGSERIAL PRIMARY KEY,
    server_id VARCHAR(36) NOT NULL REFERENCES servers(id),
    cpu_usage DOUBLE PRECISION NOT NULL,
    memory_usage DOUBLE PRECISION NOT NULL,
    disk_usage DOUBLE PRECISION NOT NULL,
    network_rx BIGINT NOT NULL,
    network_tx BIGINT NOT NULL,
    processes JSONB NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## 데이터 보존 정책

### 메트릭 데이터
- **보존 기간**: 30일
- **집계 정책**: 
  - 실시간 데이터: 1초 간격
  - 저장 데이터: 5초 간격
  - 집계 데이터: 1시간/1일 간격

### 인덱스 전략
```sql
-- 메트릭 조회 최적화
CREATE INDEX idx_metrics_server_time 
ON metrics_snapshots(server_id, timestamp);

-- 서버 호스트명 조회
CREATE INDEX idx_servers_hostname_port 
ON servers(hostname, port);
```

## 백업 전략

### 1. 전체 백업
- PostgreSQL pg_dump를 사용한 일일 백업
- 백업 보존 기간: 7일

### 2. 증분 백업
- WAL 아카이빙을 통한 지속적인 백업
- 복구 시점 목표(RPO): 5분

## 보안

### 1. 데이터 암호화
- 서버 비밀번호 AES-GCM 암호화 저장
- 사용자 비밀번호 Argon2 해싱

### 2. 접근 제어
- 역할 기반 접근 제어(RBAC)
- 연결 SSL/TLS 암호화

## 성능 최적화

### 1. TimescaleDB 최적화
- Chunk 크기: 1일
- 압축 활성화 (7일 이상 된 데이터)

### 2. 쿼리 최적화
```sql
-- 효율적인 메트릭 조회
WITH time_series AS (
    SELECT generate_series($2, $3, '1 minute'::interval) as ts
)
SELECT 
    ts,
    COALESCE(cpu_usage, 0.0) as cpu,
    COALESCE(memory_usage, 0.0) as memory
FROM time_series
LEFT JOIN metrics_snapshots ms 
    ON ms.timestamp <= ts 
    AND ms.timestamp > ts - '1 minute'::interval
WHERE ms.server_id = $1
```