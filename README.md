# FLick - 실시간 서버 모니터링 시스템

서버 리소스와 성능을 실시간으로 모니터링하고 관리하는 크로스 플랫폼 애플리케이션

## 시스템 아키텍처

```mermaid
graph TB
    subgraph Client["Flutter Client"]
        UI[UI Components]
        StateManagement["Provider\nState Management"]
        subgraph Services["Client Services"]
            WS[WebSocket Service]
            API[API Service]
            Auth[Auth Service]
            Storage[Storage Service]
        end
    end

    subgraph Server["Rust Server"]
        Router["Actix-web Router"]
        subgraph Handlers["Server Components"]
            WSHandler["WebSocket Handler\n(Real-time Metrics)"]
            APIHandler["API Handlers\n(Server Management)"]
            Monitor["Metrics Collector\n(sysinfo)"]
            AuthMiddleware["JWT Auth Middleware"]
        end
    end

    subgraph Database["PostgreSQL + TimescaleDB"]
        Metrics["Metrics\n(Hypertable)"]
        Servers[Server Info]
        Users[User Data]
        Alerts[Alert Config]
    end

    UI --> StateManagement
    StateManagement --> Services
    WS <--> |"WebSocket\n(Real-time Metrics)"| WSHandler
    API <--> |"REST API\n(Management)"| Router
    
    Router --> AuthMiddleware
    AuthMiddleware --> Handlers
    WSHandler --> Monitor
    Monitor --> Metrics
    APIHandler --> Servers
    APIHandler --> Users
    APIHandler --> Alerts

    classDef client fill:#e3f2fd,stroke:#1565c0
    classDef server fill:#fff3e0,stroke:#ef6c00
    classDef database fill:#e8f5e9,stroke:#2e7d32
    
    class Client client
    class Server server
    class Database database
```

## 주요 기능

### 실시간 모니터링
- CPU, 메모리, 디스크, 네트워크 사용량 실시간 트래킹
- 프로세스별 리소스 사용량 모니터링 (Top 10 CPU 사용 프로세스)
- WebSocket 기반 실시간 메트릭스 스트리밍

### 알림 시스템
- 리소스 사용량 임계치 기반 알림
- 심각도 레벨별 알림 관리 (info/warning/critical)
- 이메일 및 인앱 알림 지원

### 멀티 플랫폼 지원
- iOS / Android 네이티브 앱
- 소셜 로그인 지원 (Google, Apple, Kakao, Facebook)
- Material Design 3 기반 모던 UI

## 기술 스택

### Frontend (Flutter)
- **상태 관리**: Provider + Riverpod
- **차트/시각화**: fl_chart, syncfusion_flutter_charts
- **네트워크**:
  - WebSocket: web_socket_channel
  - HTTP: dio
- **인증**: flutter_secure_storage, JWT
- **UI**: Material 3, flutter_animate, shimmer

### Backend (Rust)
- **웹 프레임워크**: actix-web 4.x
- **실시간 통신**: actix-web-actors
- **시스템 모니터링**: sysinfo
- **인증**: jsonwebtoken, bcrypt
- **비동기 런타임**: tokio

### Database
- **PostgreSQL 15.0+** 
- **TimescaleDB 2.11.0+** (시계열 데이터 최적화)
- **주요 기능**:
  - 하이퍼테이블 기반 메트릭스 저장
  - 자동 파티셔닝
  - 데이터 보존 정책 관리

## 프로젝트 구조

```
flick/
├── flutter_client/          # Flutter 애플리케이션
│   ├── lib/
│   │   ├── models/         # 데이터 모델
│   │   ├── providers/      # 상태 관리
│   │   ├── screens/        # UI 화면
│   │   ├── services/       # 네트워크 서비스
│   │   └── widgets/        # 재사용 가능한 위젯
│   └── assets/             # 리소스 파일
├── rust_server/            # Rust 백엔드
│   ├── src/
│   │   ├── api/           # REST API 엔드포인트
│   │   ├── auth/          # 인증 관련 로직
│   │   ├── monitoring/    # 시스템 모니터링
│   │   └── websocket/     # WebSocket 핸들러
│   └── migrations/        # DB 마이그레이션
└── docs/                  # 프로젝트 문서
```

## 시작하기

### 요구사항
- Rust 1.75.0+
- Flutter 3.19.0+
- PostgreSQL 15.0+
- TimescaleDB 2.11.0+

### 환경 설정

1. 데이터베이스 설정
```bash
# PostgreSQL 설치 및 TimescaleDB 확장 활성화
psql -U postgres
CREATE DATABASE flickdb;
\c flickdb
CREATE EXTENSION IF NOT EXISTS timescaledb;
```

2. 환경 변수 설정
```env
DATABASE_URL=postgresql://user:password@localhost:5432/flickdb
HOST=127.0.0.1
PORT=8080
JWT_SECRET=your-secret-key
ENCRYPTION_KEY=your-encryption-key
ENCRYPTION_NONCE=your-encryption-nonce
RUST_LOG=debug
```

3. 서버 실행
```bash
cd rust_server
cargo run
```

4. 클라이언트 실행
```bash
cd flutter_client
flutter pub get
flutter run
```

## 데이터베이스 구조

### 주요 테이블
- **users**: 사용자 정보 및 인증
- **servers**: 모니터링 대상 서버 정보
- **metrics_snapshots**: 실시간 메트릭스 데이터 (TimescaleDB 하이퍼테이블)
- **alerts**: 알림 설정 및 이력
- **logs**: 시스템 로그

### 보안 기능
- JWT 기반 인증
- 비밀번호 bcrypt 해싱
- AES-GCM 기반 서버 인증정보 암호화

## API 문서

### WebSocket 엔드포인트
- **실시간 메트릭스**: `ws://{host}/api/v1/ws`
  - 서버별 리소스 사용량 실시간 스트리밍
  - 자동 재연결 및 heartbeat 처리

### REST API
- **서버 관리**: `/api/v1/servers`
- **알림 설정**: `/api/v1/alerts`
- **로그 조회**: `/api/v1/logs`
- **인증**: `/api/v1/auth`

## 라이선스

MIT License
