// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/constants.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/server_provider.dart';
import 'providers/settings_provider.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_client/services/log_service.dart';
import 'providers/log_provider.dart';

import 'services/log_service.dart';
import 'providers/log_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 시스템 UI 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 서비스 초기화
  final storageService = await StorageService.initialize();
  final apiService = ApiService(baseUrl: AppConstants.baseUrl);
  final authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );
  final logService = LogService(apiService: apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ServerProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService),
        ),
        // 로그 관련 Provider 추가
        Provider<LogService>(
          create: (_) => logService,
        ),
        ChangeNotifierProvider(
          create: (context) => LogProvider(
            logService: logService,
          ),
        ),
      ],
      child: const App(),
    ),
  );
}
