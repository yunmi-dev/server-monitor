# REST API 명세

## 인증

### POST /api/v1/auth/login
소셜 로그인 또는 이메일/비밀번호 로그인

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "password"
}
```

**Response**
```json
{
  "access_token": "jwt-token",
  "refresh_token": "refresh-token",
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name",
    "role": "user"
  }
}
```

## 서버 관리

### GET /api/v1/servers
모니터링 중인 서버 목록 조회

**Response**
```json
[
  {
    "id": "server-id",
    "name": "Server Name",
    "hostname": "example.com",
    "port": 22,
    "type": "linux",
    "category": "physical",
    "is_online": true,
    "created_at": "2024-03-09T00:00:00Z"
  }
]
```

### POST /api/v1/servers
새 서버 추가

**Request Body**
```json
{
  "name": "Production Server",
  "host": "example.com",
  "port": 22,
  "username": "admin",
  "password": "password",
  "type": "linux",
  "category": "physical"
}
```

### GET /api/v1/servers/{id}
특정 서버 정보 조회

**Response**
```json
{
  "id": "server-id",
  "name": "Server Name",
  "hostname": "example.com",
  "status": {
    "cpu_usage": 45.2,
    "memory_usage": 78.5,
    "disk_usage": 65.0,
    "network_usage": "1.2 MB/s"
  }
}
```

### DELETE /api/v1/servers/{id}
서버 삭제

## 메트릭

### GET /api/v1/servers/{id}/metrics
서버 메트릭 이력 조회

**Query Parameters**
- `from`: DateTime (ISO8601)
- `to`: DateTime (ISO8601)

**Response**
```json
{
  "metrics": [
    {
      "timestamp": "2024-03-09T12:00:00Z",
      "cpu_usage": 45.2,
      "memory_usage": 78.5,
      "disk_usage": 65.0,
      "network_rx": 1024,
      "network_tx": 2048
    }
  ]
}
```

## 로그

### GET /api/v1/logs
서버 로그 조회

**Query Parameters**
- `server_id`: String
- `levels`: String[] (debug, info, warning, error)
- `from`: DateTime
- `to`: DateTime
- `search`: String

**Response**
```json
{
  "logs": [
    {
      "id": "log-id",
      "level": "info",
      "message": "Log message",
      "timestamp": "2024-03-09T12:00:00Z",
      "server_id": "server-id"
    }
  ]
}
```

## 알림

### GET /api/v1/alerts
알림 목록 조회

**Response**
```json
{
  "alerts": [
    {
      "id": "alert-id",
      "server_id": "server-id",
      "type": "cpu_usage",
      "severity": "warning",
      "message": "CPU usage exceeded 80%",
      "created_at": "2024-03-09T12:00:00Z"
    }
  ]
}
```

### PATCH /api/v1/alerts/{id}/acknowledge
알림 확인 처리

## 오류 응답

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Error message"
  }
}
```

공통 오류 코드:
- 400: 잘못된 요청
- 401: 인증 필요
- 403: 권한 없음
- 404: 리소스 없음
- 500: 서버 오류