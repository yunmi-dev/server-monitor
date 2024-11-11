// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          title: 'Flick',
          theme: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFFFF4081),
            scaffoldBackgroundColor: Colors.black,
          ),
          // home: const LoginScreen(), // 임시로 주석 처리
          home: const DashboardScreen(), // 대시보드 화면으로 변경
        ));
  }
}
