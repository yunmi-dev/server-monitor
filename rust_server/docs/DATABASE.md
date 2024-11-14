# FLick - 서버 모니터링 시스템 설계

## Database Design Documentation

This document outlines the database structure for the FLick Server Monitoring System.

## Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    Users ||--o{ Servers : manages
    Users ||--o{ Alerts : configures
    Users ||--o{ User_Settings : has
    Servers ||--o{ Server_Metrics : generates
    Servers ||--o{ Processes : runs
    Servers ||--o{ Server_Settings : has
    Alerts ||--o{ Alert_History : triggers
    Servers ||--o{ Alerts : monitors

    Users {
        uuid user_id PK "사용자 고유 식별자"
        string email UK "이메일 (로그인 ID)"
        string name "사용자 이름"
        string provider "인증 제공자 (Google/Kakao/Facebook)"
        string provider_id "외부 인증 고유 ID"
        boolean email_verified "이메일 인증 여부"
        string refresh_token "리프레시 토큰"
        timestamp created_at "계정 생성일시"
        timestamp last_login_at "최종 로그인일시"
        timestamp updated_at "정보 수정일시"
    }

    User_Settings {
        uuid setting_id PK "설정 고유 식별자"
        uuid user_id FK "사용자 ID"
        boolean alert_email "이메일 알림 사용"
        boolean alert_push "푸시 알림 사용"
        string timezone "타임존"
        string language "언어 설정"
        timestamp updated_at "설정 수정일시"
    }

    Servers {
        uuid server_id PK "서버 고유 식별자"
        uuid user_id FK "서버 소유자 ID"
        string name "서버 이름"
        string hostname "호스트명"
        string ip_address "IP 주소"
        string description "서버 설명"
        string api_key "서버 인증 키"
        boolean is_active "활성화 상태"
        timestamp last_ping "최근 응답 시간"
        timestamp created_at "서버 등록일시"
        timestamp updated_at "정보 수정일시"
    }

    Server_Settings {
        uuid setting_id PK "설정 고유 식별자"
        uuid server_id FK "서버 ID"
        integer metric_interval "메트릭 수집 주기(초)"
        integer retention_days "데이터 보관 기간(일)"
        boolean process_monitoring "프로세스 모니터링 사용"
        timestamp updated_at "설정 수정일시"
    }

    Server_Metrics {
        uuid metric_id PK "메트릭 고유 식별자"
        uuid server_id FK "서버 ID"
        timestamp time_bucket "측정 시간"
        float cpu_usage "CPU 사용률 (%)"
        float memory_total "전체 메모리 (bytes)"
        float memory_used "사용 메모리 (bytes)"
        float disk_total "전체 디스크 (bytes)"
        float disk_used "사용 디스크 (bytes)"
        float network_in "네트워크 수신량 (bytes)"
        float network_out "네트워크 송신량 (bytes)"
        json additional_metrics "추가 메트릭 (JSON)"
    }

    Processes {
        uuid process_id PK "프로세스 고유 식별자"
        uuid server_id FK "서버 ID"
        timestamp time_bucket "측정 시간"
        string name "프로세스 이름"
        integer pid "프로세스 ID"
        float cpu_usage "CPU 사용률 (%)"
        float memory_usage "메모리 사용량 (bytes)"
        string status "프로세스 상태"
        string user "실행 사용자"
        integer threads "스레드 수"
    }

    Alerts {
        uuid alert_id PK "알림 설정 고유 식별자"
        uuid server_id FK "서버 ID"
        uuid user_id FK "사용자 ID"
        string name "알림 이름"
        string metric_type "메트릭 유형"
        float threshold "임계값"
        string condition "조건 (>, <, =, >=, <=)"
        string severity "심각도 (info/warning/critical)"
        boolean is_active "활성화 여부"
        integer cooldown "재알림 대기시간(분)"
        timestamp created_at "설정 생성일시"
        timestamp updated_at "설정 수정일시"
    }

    Alert_History {
        uuid history_id PK "알림 기록 고유 식별자"
        uuid alert_id FK "알림 설정 ID"
        uuid server_id FK "서버 ID"
        timestamp triggered_at "알림 발생시간"
        float value "측정값"
        string status "상태 (triggered/resolved)"
        text message "알림 메시지"
        timestamp resolved_at "해결 시간"
    }
```

## Database Design Features

### TimescaleDB Integration

- Server_Metrics and Processes tables are implemented as TimescaleDB hypertables
- Automatic partitioning by time for efficient time-series data management
- Configurable retention policy through retention_days setting

### Key Design Considerations

#### Security

- API key authentication for server monitoring
- OAuth provider integration with separate provider IDs
- Email verification system
- Refresh token management

#### Scalability

- UUID usage for distributed systems compatibility
- JSON support for extensible metrics
- Separated settings tables for flexible configuration
- TimescaleDB partitioning for high-volume data

#### Monitoring Features

- Comprehensive server metrics tracking
- Detailed process monitoring
- Flexible alert system with severity levels
- Customizable metric collection intervals

#### User Experience

- Multiple authentication providers
- Timezone and language preferences
- Configurable alert notifications
- Alert cooldown prevention

## Implementation Notes

```sql
-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create hypertables for time-series data
SELECT create_hypertable('server_metrics', 'time_bucket');
SELECT create_hypertable('processes', 'time_bucket');

-- Set up retention policy
SELECT add_retention_policy('server_metrics', INTERVAL '1 day' * :retention_days);
SELECT add_retention_policy('processes', INTERVAL '1 day' * :retention_days);
```