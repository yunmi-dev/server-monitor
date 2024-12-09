# 개발 시작 가이드

## 개발 환경 설정

### 1. Flutter 환경 설정
```bash
# Flutter SDK 설치
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# 의존성 설치
flutter pub get

# 개발 환경 확인
flutter doctor
```

### 2. Rust 환경 설정
```bash
# Rust 설치
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# 의존성 확인
cargo check
```

### 3. 데이터베이스 설정
```bash
# PostgreSQL & TimescaleDB 설치
sudo apt install postgresql
sudo apt install timescaledb-postgresql-15

# 데이터베이스 생성
psql -U postgres
CREATE DATABASE flickdb;
\c flickdb
CREATE EXTENSION IF NOT EXISTS timescaledb;
```

## 프로젝트 설정

### 1. 환경 변수 설정
```bash
# .env 파일 생성
cat > .env << EOL
DATABASE_URL=postgresql://user:password@localhost:5432/flickdb
HOST=127.0.0.1
PORT=8080
JWT_SECRET=your-secret-key
ENCRYPTION_KEY=your-32-byte-key
ENCRYPTION_NONCE=your-12-byte-nonce
RUST_LOG=debug
EOL
```

### 2. 데이터베이스 마이그레이션
```bash
cd rust_server
cargo install sqlx-cli
sqlx migrate run
```

### 3. 클라이언트 설정
```dart
// lib/config/constants.dart 수정
static const String baseUrl = 'http://localhost:8080/api/v1';
static const String wsUrl = 'ws://localhost:8080/api/v1/ws';
```

## 실행 방법

### 1. 서버 실행
```bash
cd rust_server
cargo run
```

### 2. 클라이언트 실행
```bash
cd flutter_client
flutter run
```

## 개발 워크플로우

### 1. 브랜치 전략
- `main`: 안정 버전
- `develop`: 개발 브랜치
- `feature/*`: 기능 개발
- `fix/*`: 버그 수정

### 2. 코드 스타일
```bash
# Rust 코드 포맷팅
cargo fmt

# Flutter 코드 포맷팅
flutter format .
```

### 3. 테스트
```bash
# Rust 테스트
cargo test

# Flutter 테스트
flutter test
```

## 디버깅

### 1. 로그 확인
```rust
// Rust 서버
RUST_LOG=debug cargo run

// Flutter
debugPrint('Debug message');
```

### 2. 디버거 설정
- VS Code launch.json 설정
- Flutter DevTools 사용

## 문제 해결

### 1. 데이터베이스 연결 문제
```bash
# PostgreSQL 상태 확인
sudo service postgresql status

# 로그 확인
tail -f /var/log/postgresql/postgresql-15-main.log
```

### 2. WebSocket 연결 문제
- 네트워크 설정 확인
- 방화벽 규칙 확인
- SSL/TLS 인증서 확인