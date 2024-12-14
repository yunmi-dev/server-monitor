// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/app.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/services/auth_service.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/providers/settings_provider.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'package:flutter_client/providers/theme_provider.dart';
import 'package:flutter_client/services/log_service.dart';
import 'package:flutter_client/providers/log_provider.dart';
import 'package:flutter_client/providers/alert_provider.dart';
import 'package:flutter_client/services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 서비스 초기화
  final storageService = await StorageService.initialize();
  final apiService = ApiService(baseUrl: AppConstants.baseUrl);
  final authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );
  final logService = LogService(apiService: apiService);

  // WebSocket 서비스 초기화 및 연결
  final webSocketService = WebSocketService.instance;
  await webSocketService.connect(); // WebSocket 연결 시작

  // 프로바이더 설정 및 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            authService: authService,
            storageService: storageService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => ServerProvider(
            apiService: apiService,
            webSocketService: webSocketService, // WebSocketService 주입
          ),
        ),
        Provider<LogService>(
          create: (_) => logService,
        ),
        ChangeNotifierProvider(
          create: (context) => LogProvider(
            logService: logService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AlertProvider(apiService),
        ),
      ],
      child: const App(),
    ),
  );
}
