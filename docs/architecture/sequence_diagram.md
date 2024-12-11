# Sequence Diagram

## 개요

본 문서는 애플리케이션의 인증 시스템 흐름을 설명합니다.

## Sequence Diagram

```mermaid
sequenceDiagram
   actor Client
   participant Flutter as Flutter Client
   participant Auth as Auth Service
   participant Rust as Rust Server
   participant DB as Database

   %% Email 로그인 흐름
   Client->>Flutter: 인증 정보 입력
   Flutter->>Auth: signInWithEmail(email, password)
   Auth->>Rust: POST /auth/login
   Rust->>DB: 이메일로 사용자 조회
   DB-->>Rust: 사용자 데이터
   Rust->>Rust: 비밀번호 검증
   Rust->>Rust: JWT 토큰 생성
   Rust-->>Auth: 인증 응답 (토큰, 사용자 정보)
   Auth->>Auth: 토큰 저장
   Auth-->>Flutter: 인증 상태 갱신

   %% 소셜 로그인 흐름
   Client->>Flutter: 소셜 로그인 선택
   Flutter->>Auth: signInWithProvider()
   Auth->>Auth: OAuth 인증 흐름
   Auth->>Rust: POST /auth/social-login
   Rust->>DB: 사용자 조회/생성
   DB-->>Rust: 사용자 데이터
   Rust->>Rust: JWT 토큰 생성
   Rust-->>Auth: 인증 응답
   Auth->>Auth: 토큰 저장
   Auth-->>Flutter: 인증 상태 갱신

   %% 토큰 갱신 흐름
   Auth->>Auth: 토큰 만료
   Auth->>Rust: POST /auth/refresh
   Rust->>Rust: Refresh 토큰 검증
   Rust->>Rust: 새 Access 토큰 생성
   Rust-->>Auth: 새 토큰
   Auth->>Auth: 토큰 갱신

