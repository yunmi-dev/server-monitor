// lib/widgets/auth/unified_social_login.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/utils/snackbar_utils.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/widgets/auth/social_login_button.dart';

class UnifiedSocialLogin extends StatelessWidget {
  const UnifiedSocialLogin({super.key});

  Future<void> _handleSocialLogin(
    BuildContext context,
    String provider,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      switch (provider.toLowerCase()) {
        case 'apple':
          await authProvider.signInWithApple();
          break;
        case 'kakao':
          await authProvider.signInWithKakao();
          break;
        case 'google':
          await authProvider.signInWithGoogle();
          break;
        case 'facebook':
          await authProvider.signInWithFacebook();
          break;
      }

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, AppConstants.loginSuccess);
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 소셜 로그인 설정을 배열로 정의
    final socialLogins = [
      {
        'provider': 'apple',
        'backgroundColor': Colors.black,
        'textColor': Colors.white,
        'iconPath': 'assets/icons/apple.png',
        'text': 'Apple로 계속하기',
      },
      {
        'provider': 'kakao',
        'backgroundColor': const Color(0xFFFEE500),
        'textColor': Colors.black87,
        'iconPath': 'assets/icons/kakao.png',
        'text': '카카오로 계속하기',
      },
      {
        'provider': 'google',
        'backgroundColor': Colors.white,
        'textColor': Colors.black87,
        'iconPath': 'assets/icons/google.png',
        'text': 'Google로 계속하기',
      },
      {
        'provider': 'facebook',
        'backgroundColor': const Color(0xFF1877F2),
        'textColor': Colors.white,
        'iconPath': 'assets/icons/facebook.png',
        'text': 'Facebook으로 계속하기',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing,
      ),
      child: Column(
        children: [
          for (final login in socialLogins)
            SocialLoginButton(
              provider: login['provider'] as String,
              onPressed: () =>
                  _handleSocialLogin(context, login['provider'] as String),
              backgroundColor: login['backgroundColor'] as Color,
              textColor: login['textColor'] as Color?,
              iconPath: login['iconPath'] as String,
              text: login['text'] as String,
            ),
        ],
      ),
    );
  }
}
