# 시스템 요구사항

## 개발 환경

### Flutter 클라이언트
- Flutter SDK: 3.19.0+
- Dart SDK: ^3.5.3
- Android Studio / VS Code
- Git

### Rust 서버
- Rust 1.75.0+
- Cargo
- PostgreSQL 15.0+
- TimescaleDB 2.11.0+

## 필수 의존성

### Frontend 패키지
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  flutter_riverpod: ^2.6.1
  fl_chart: ^0.69.2
  dio: ^5.7.0
  web_socket_channel: ^3.0.1
  shared_preferences: ^2.3.3
```

### Backend 크레이트
```toml
[dependencies]
actix-web = "4.4"
tokio = { version = "1.0", features = ["full"] }
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-rustls"] }
serde = { version = "1.0", features = ["derive"] }
```

## 하드웨어 요구사항

### 클라이언트
- **모바일**:
  - Android 6.0+
  - iOS 12.0+
  - 2GB+ RAM
- **데스크톱**:
  - Windows 10+
  - macOS 10.15+
  - Linux (최신 배포판)
  - 4GB+ RAM

### 서버
- **최소 사양**:
  - 2 CPU 코어
  - 4GB RAM
  - 20GB 저장공간
  
- **권장 사양**:
  - 4 CPU 코어
  - 8GB RAM
  - 50GB+ SSD

## 네트워크 요구사항

### 포트
- TCP 8080: API 서버
- TCP 5432: PostgreSQL
- TCP/UDP: WebSocket 통신

### 대역폭
- 최소: 1Mbps
- 권장: 10Mbps+

## 데이터베이스

### PostgreSQL
- 버전: 15.0+
- TimescaleDB 확장: 2.11.0+
- 문자셋: UTF-8
- 최소 저장공간: 10GB

## 보안 요구사항

### 인증서
- HTTPS를 위한 SSL/TLS 인증서
- WSS 지원

### 방화벽
- 80/443: HTTPS
- 8080: API 서버
- 5432: PostgreSQL (내부 네트워크만)