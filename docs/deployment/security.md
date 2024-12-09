# 보안 가이드

## 인증 시스템

### JWT 인증
```rust
pub struct Claims {
    pub sub: String,     // 사용자 ID
    pub email: String,   // 이메일
    pub role: UserRole,  // 사용자 권한
    pub exp: i64,        // 만료 시간
    pub iat: i64,        // 발급 시간
    pub token_type: String, // 토큰 타입
}
```

### 토큰 관리
1. **접근 토큰 (Access Token)**
   - 유효기간: 15분
   - 용도: API 요청 인증
   - 형식: Bearer 토큰

2. **갱신 토큰 (Refresh Token)**
   - 유효기간: 7일
   - 용도: 접근 토큰 갱신
   - 저장: 안전한 저장소

## 데이터 암호화

### AES-GCM 암호화
```rust
pub struct Encryptor {
    cipher: Aes256Gcm,
    nonce: [u8; 12],
}
```

#### 키 관리
- 32바이트 암호화 키 (Base64 인코딩)
- 12바이트 nonce (Base64 인코딩)
- 환경 변수를 통한 안전한 키 관리

#### 사용 예시
```rust
// 암호화
let encrypted = encryptor.encrypt("sensitive_data")?;

// 복호화
let decrypted = encryptor.decrypt(&encrypted)?;
```

## API 보안

### 인증 미들웨어
```rust
// 공개 엔드포인트
let public_paths = [
    "/api/v1/auth/login",
    "/api/v1/auth/register",
    "/api/v1/auth/social-login",
    "/api/v1/auth/refresh",
    "/api/v1/health",
    "/api/v1/ws",
    "/api/v1/servers/test-connection"
];
```

### 보안 헤더
```rust
// 필수 헤더
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

## 웹소켓 보안

### 연결 인증
1. 최초 연결 시 JWT 토큰 검증
2. 주기적 heartbeat 검사 (30초)
3. 연결 타임아웃 관리 (60초)

### 메시지 보안
- JSON 페이로드 검증
- 서버별 구독 권한 확인

## 데이터베이스 보안

### 비밀번호 저장
- Argon2 해싱 알고리즘 사용
- 솔트(Salt) 자동 생성

### 서버 인증정보
```sql
CREATE TABLE servers (
    ...
    username VARCHAR(255) NOT NULL,
    encrypted_password TEXT NOT NULL,
    ...
);
```

## 환경 설정

### 필수 환경 변수
```env
JWT_SECRET=<your-jwt-secret>
ENCRYPTION_KEY=<your-32-byte-key-base64>
ENCRYPTION_NONCE=<your-12-byte-nonce-base64>
```

### 키 생성 도구
```rust
// 새로운 암호화 키 생성
let new_key = Encryptor::generate_key();
let new_nonce = Encryptor::generate_nonce();
```

## 보안 체크리스트

### 배포 전 확인사항
- [ ] 모든 환경 변수 설정 완료
- [ ] HTTPS/WSS 설정
- [ ] 데이터베이스 접근 제한
- [ ] 로그에 민감정보 노출 없음
- [ ] 적절한 CORS 설정
- [ ] 에러 메시지에 민감정보 노출 없음

### 운영 시 주의사항
1. **토큰 관리**
   - 정기적인 키 로테이션
   - 만료된 토큰 정리

2. **모니터링**
   - 비정상 접근 시도 감시
   - 리소스 사용량 모니터링

3. **업데이트**
   - 보안 패치 정기 적용
   - 의존성 패키지 버전 관리

## 장애 대응

### 인증 실패 대응
1. 토큰 만료
   - 갱신 토큰으로 새로운 접근 토큰 발급
   - 갱신 실패 시 재로그인 요청

2. 비정상 토큰
   - 로그인 페이지로 리디렉션
   - 관련 로그 기록

### 암호화 실패 대응
1. 키 문제
   - 백업 키로 복구 시도
   - 관리자에게 알림

2. 데이터 손상
   - 백업에서 복구
   - 장애 기록 및 분석