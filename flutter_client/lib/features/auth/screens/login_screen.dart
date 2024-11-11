// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              'FLick',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 40),
            SocialLoginButton(
              text: 'Continue with Apple',
              backgroundColor: Colors.black87,
              onPressed: () {
                context.read<AuthProvider>().signInWithApple();
              },
              icon: const Icon(Icons.apple, color: Colors.white),
            ),
            SocialLoginButton(
              text: 'Continue with Kakao',
              backgroundColor: const Color(0xFFFEE500),
              textColor: Colors.black87,
              onPressed: () {
                context.read<AuthProvider>().signInWithKakao();
              },
            ),
            SocialLoginButton(
              text: 'Continue with Google',
              backgroundColor: Colors.white,
              textColor: Colors.black87,
              onPressed: () {
                context.read<AuthProvider>().signInWithGoogle();
              },
              icon: Image.asset('assets/google_logo.png', height: 24),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Email Sign In
              },
              child: const Text('이미 계정이 있으신가요?'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
