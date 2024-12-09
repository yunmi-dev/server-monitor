# FLick Server

실시간 서버 모니터링을 위한 Rust 기반 백엔드 서버

## 기능 구조

- **실시간 모니터링**: sysinfo 기반 시스템 메트릭 수집
- **WebSocket**: 클라이언트에 실시간 메트릭 스트리밍
- **보안**: JWT 기반 인증 및 AES-GCM 암호화
- **시계열 데이터**: TimescaleDB 활용 메트릭 저장

## 기술 스택

- **웹 프레임워크**: Actix-web 4.x
- **데이터베이스**: 
  - PostgreSQL 15.x
  - TimescaleDB (시계열 데이터 최적화)
- **비동기 런타임**: Tokio
- **시스템 모니터링**: sysinfo
- **인증/보안**:
  - JWT (jsonwebtoken)
  - AES-GCM 암호화
  - Argon2 비밀번호 해싱

## Project Structure
```
src/
├── api/                 # REST API 엔드포인트
│   ├── alerts.rs       # 알림 관련 핸들러
│   ├── servers.rs      # 서버 관리 핸들러
│   ├── logs.rs         # 로그 관리
│   └── routes.rs       # 라우트 설정
├── auth/               # 인증 관련
│   ├── jwt.rs          # JWT 토큰 처리
│   ├── middleware.rs   # 인증 미들웨어
│   └── types.rs        # 인증 타입 정의
├── monitoring/         # 모니터링 시스템
│   ├── collector.rs    # 메트릭 수집기
│   └── mod.rs          # 모니터링 서비스
├── websocket/         # WebSocket 처리
│   └── handlers.rs     # WebSocket 연결 관리
└── db/                # 데이터베이스
    ├── models.rs       # 데이터 모델
    └── repository.rs   # DB 작업 추상화
```

## 시작하기

### 요구사항

- Rust 1.75.0+
- PostgreSQL 15.0+
- TimescaleDB 2.11.0+

### 환경 설정

1. TimescaleDB 설치 및 설정
```bash
# PostgreSQL에 TimescaleDB 확장 추가
psql -U postgres
CREATE DATABASE flickdb;
\c flickdb
CREATE EXTENSION IF NOT EXISTS timescaledb;
```

2. 환경 변수 설정 (.env 파일)
```env
DATABASE_URL=postgresql://user:password@localhost:5432/flickdb
HOST=127.0.0.1
PORT=8080
JWT_SECRET=your-secret-key
ENCRYPTION_KEY=your-32-byte-key
ENCRYPTION_NONCE=your-12-byte-nonce
RUST_LOG=debug
```

3. 데이터베이스 마이그레이션
```bash
cargo install sqlx-cli
sqlx migrate run
```

4. 서버 실행
```bash
cargo run --release
```

## API 엔드포인트

### 인증
- `POST /api/v1/auth/login`: 로그인
- `POST /api/v1/auth/register`: 회원가입

### 서버 관리
- `GET /api/v1/servers`: 서버 목록 조회
- `POST /api/v1/servers`: 새 서버 추가
- `GET /api/v1/servers/{id}`: 서버 상세 정보
- `DELETE /api/v1/servers/{id}`: 서버 삭제

### 모니터링
- `GET /api/v1/servers/{id}/metrics`: 서버 메트릭 조회
- `WS /api/v1/ws`: 실시간 메트릭 스트리밍

### 로그
- `GET /api/v1/logs`: 로그 조회
- `POST /api/v1/logs`: 로그 생성

## WebSocket 프로토콜

### 메시지 포맷
```json
{
  "type": "resource_metrics",
  "data": {
    "serverId": "server-id",
    "cpuUsage": 45.2,
    "memoryUsage": 78.5,
    "diskUsage": 65.0,
    "networkUsage": 1024,
    "timestamp": "2024-03-09T12:00:00Z"
  }
}
```

### 메트릭 구독
```json
{
  "type": "server_metrics.subscribe",
  "data": {
    "serverId": "server-id"
  }
}
```

## 보안

### 데이터베이스 보안
- 서버 인증 정보 AES-GCM 암호화 저장
- 사용자 비밀번호 Argon2 해싱

### API 보안
- JWT 기반 인증
- Rate limiting
- CORS 설정

## 모니터링 설정

### 메트릭 수집 간격
- 기본 수집 간격: 1초
- 저장 간격: 5초
- 데이터 보존 기간: 30일

### 알림 임계값
```rust
AlertThresholds {
    cpu_warning: 80.0,    // CPU 경고 임계값 (%)
    cpu_critical: 90.0,   // CPU 위험 임계값 (%)
    memory_warning: 80.0, // 메모리 경고 임계값 (%)
    memory_critical: 90.0 // 메모리 위험 임계값 (%)
}
```

## 개발 가이드

### 새로운 API 엔드포인트 추가
1. `src/api/` 디렉토리에 핸들러 구현
2. `src/api/routes.rs`에 라우트 추가
3. 필요한 경우 저장소 메서드 구현 (`src/db/repository.rs`)

### 테스트
```bash
# 단위 테스트 실행
cargo test

# 통합 테스트 실행
cargo test --test '*'
```

## 라이선스

MIT License - [LICENSE](LICENSE) 파일 참조