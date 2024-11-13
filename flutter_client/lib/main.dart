// lib/main.dart

import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator(); // 앱 시작 전에 서비스 로케이터 초기화
  runApp(const App());
}
