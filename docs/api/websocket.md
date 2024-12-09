# WebSocket API 명세

## 연결

### Endpoint
```
ws://server:port/api/v1/ws
```

### Headers
```
Authorization: Bearer <jwt-token>
```

## 메시지 형식

### 1. 클라이언트 → 서버

#### 서버 메트릭 구독
```json
{
  "type": "server_metrics.subscribe",
  "data": {
    "serverId": "server-id"
  }
}
```

#### 구독 해제
```json
{
  "type": "server_metrics.unsubscribe",
  "data": {
    "serverId": "server-id"
  }
}
```

### 2. 서버 → 클라이언트

#### 리소스 메트릭 업데이트
```json
{
  "type": "resource_metrics",
  "data": {
    "serverId": "server-id",
    "cpuUsage": 45.2,
    "memoryUsage": 78.5,
    "diskUsage": 65.0,
    "networkUsage": 1024.0,
    "processCount": 128,
    "processes": [
      {
        "pid": 1234,
        "name": "process-name",
        "cpuUsage": 12.5,
        "memoryUsage": 1024
      }
    ],
    "timestamp": "2024-03-09T12:00:00Z"
  }
}
```

#### 오류 메시지
```json
{
  "type": "error",
  "data": {
    "message": "Error message",
    "serverId": "server-id"
  }
}
```

## 연결 관리

### Heartbeat
- 간격: 30초
- 형식:
  ```json
  {
    "type": "ping",
    "timestamp": "2024-03-09T12:00:00Z"
  }
  ```

### 재연결
- 연결 끊김 시 5초 후 자동 재연결
- 최대 재시도 횟수: 5회

## 에러 처리

1. 인증 오류
```json
{
  "type": "error",
  "data": {
    "code": "AUTH_ERROR",
    "message": "Invalid or expired token"
  }
}
```

2. 구독 오류
```json
{
  "type": "error",
  "data": {
    "code": "SUBSCRIPTION_ERROR",
    "message": "Failed to subscribe to server metrics",
    "serverId": "server-id"
  }
}
```