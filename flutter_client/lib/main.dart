// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';

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
        home: const LoginScreen(),
      ),
    );
  }
}
