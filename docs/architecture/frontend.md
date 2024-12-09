# Frontend 아키텍처

## 앱 구조

```
lib/
├── config/           # 앱 설정
│   ├── constants.dart
│   ├── routes.dart
│   └── theme.dart
├── models/          # 데이터 모델
│   ├── server_metrics.dart
│   ├── alert.dart
│   └── user.dart
├── providers/       # 상태 관리
│   ├── server_provider.dart
│   ├── auth_provider.dart
│   └── alert_provider.dart
├── screens/         # UI 화면
│   ├── dashboard/
│   ├── servers/
│   ├── alerts/
│   └── settings/
└── services/        # 네트워크 서비스
    ├── api_service.dart
    ├── websocket_service.dart
    └── auth_service.dart
```

## 핵심 컴포넌트

### 1. 상태 관리
- Provider 패턴 사용
- 서버 상태, 인증, 알림 등 분리된 상태 관리
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ServerProvider(...)),
    ChangeNotifierProvider(create: (_) => AuthProvider(...)),
    ChangeNotifierProvider(create: (_) => AlertProvider(...)),
  ],
)
```

### 2. 네트워크 통신
- REST API: Dio 클라이언트
- WebSocket: 실시간 메트릭 수신
- 자동 재연결 및 토큰 갱신

### 3. UI 컴포넌트
```dart
// 대시보드 메인 화면
class DashboardScreen extends StatefulWidget {
  // CPU, 메모리, 디스크 사용량 표시
  // 실시간 차트 및 알림
}

// 서버 관리 화면
class ServersScreen extends StatefulWidget {
  // 서버 목록 및 상태 표시
  // 서버 추가/제거 기능
}
```

## 데이터 흐름

### 1. 실시간 메트릭 처리
```dart
WebSocketService.instance.metricsStream.listen((metrics) {
  // 메트릭 데이터 처리 및 UI 업데이트
});
```

### 2. 상태 업데이트
```dart
class ServerProvider extends ChangeNotifier {
  void updateServerStatus(String serverId, ServerStatus status) {
    // 상태 업데이트
    notifyListeners();
  }
}
```

## UI 테마

### 1. 다크 모드 지원
```dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system,
)
```

### 2. 반응형 디자인
- LayoutBuilder 사용
- 화면 크기별 최적화

## 보안

### 1. 인증 처리
- JWT 토큰 관리
- 보안 스토리지 사용
- 자동 로그아웃

### 2. 데이터 보안
- HTTPS 통신
- 민감 정보 암호화
- 세션 관리