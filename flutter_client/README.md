# FLick - Flutter Client

실시간 서버 모니터링을 위한 크로스 플랫폼 클라이언트 애플리케이션

## 주요 기능

### 1. 대시보드
- 실시간 서버 상태 모니터링
- 리소스 사용량 시각화 (CPU, 메모리, 디스크, 네트워크)
- 서버별 상태 트렌드 분석

### 2. 통계
- 리소스별 상세 사용량 추적
- 시계열 데이터 시각화
- 커스텀 기간 설정

### 3. 모니터링
- WebSocket 기반 실시간 데이터 수신
- 서버별 프로세스 모니터링
- 알림 설정 및 관리

### 4. 인증
- 이메일/비밀번호 로그인
- 소셜 로그인 (Google, Apple, Kakao, Facebook)
- JWT 기반 인증

## 기술 스택

- Flutter 3.19.0+
- Provider + Riverpod (상태 관리)
- WebSocket (실시간 통신)
- fl_chart (데이터 시각화)
- dio (HTTP 통신)

## 프로젝트 구조

```
lib/
├── config/          # 앱 설정
├── constants/       # 상수 정의
├── models/         # 데이터 모델
├── providers/      # 상태 관리
├── screens/        # UI 화면
├── services/       # 비즈니스 로직
├── utils/          # 유틸리티
└── widgets/        # 재사용 컴포넌트
```

## 시작하기

### 요구사항

- Flutter SDK 3.19.0+
- Dart SDK ^3.5.3
- Android Studio / VS Code
- iOS 개발을 위한 Xcode (Mac OS)

### 환경 설정

1. 환경 변수 설정 (`lib/config/constants.dart`)
```dart
static const String baseUrl = 'http://your-server:8080/api/v1';
static const String wsUrl = 'ws://your-server:8080/api/v1/ws';
```

2. 의존성 설치
```bash
flutter pub get
```

3. 소셜 로그인 설정
- Google: `google-services.json` / `GoogleService-Info.plist` 추가
- Kakao: `kakao_strings.xml` / `kakao_strings.json` 추가
- Facebook: Facebook Developer Console에서 앱 ID 설정
- Apple: Apple Developer Account에서 인증서 설정

### 빌드 & 실행

```bash
# 디버그 모드 실행
flutter run

# Release 빌드 (Android)
flutter build apk

# Release 빌드 (iOS)
flutter build ios
```

## 주요 기능 상세

### WebSocket 연결 관리
```dart
final webSocketService = WebSocketService.instance;
await webSocketService.connect();
webSocketService.subscribeToServerMetrics(serverId);
```

### 실시간 메트릭스 수신
```dart
webSocketService.metricsStream.listen((metrics) {
  // 메트릭스 데이터 처리
});
```

### 인증 처리
```dart
final authService = AuthService(
  apiService: apiService,
  storageService: storageService,
);

// 로그인
await authService.signInWithEmail(email, password);

// 소셜 로그인
await authService.signInWithGoogle();
```

## 상태 관리

Provider 패턴을 사용하여 앱의 상태를 관리합니다:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ServerProvider(...)),
    ChangeNotifierProvider(create: (_) => AuthProvider(...)),
    ChangeNotifierProvider(create: (_) => ThemeProvider(...)),
  ],
  child: const App(),
)
```

## 테마 설정

Material 3 디자인 시스템을 기반으로 다크/라이트 테마를 지원합니다.

## 국제화

현재 지원 언어:
- 한국어 (ko)
- 영어 (en)
- 일본어 (ja)
- 중국어 (zh)

## 라이선스

MIT License