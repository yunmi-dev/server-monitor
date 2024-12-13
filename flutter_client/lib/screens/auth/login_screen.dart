// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/widgets/auth/unified_social_login.dart';
import 'package:flutter_client/utils/validation_utils.dart';
import 'package:flutter_client/utils/snackbar_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, AppConstants.loginSuccess);
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
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

      if (mounted) {
        SnackBarUtils.showSuccess(context, AppConstants.loginSuccess);
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    }
  }

  Widget _buildSocialLoginButtons() {
    return const UnifiedSocialLogin();
  }

  Widget _buildLoginForm() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
            decoration: InputDecoration(
              labelText: '이메일',
              hintText: 'your@email.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.white.withOpacity(0.5), // 아이콘 투명도 추가
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.5), // 라벨 텍스트 투명도 추가
              ),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3), // 힌트 텍스트 투명도 추가
              ),
            ),
            style: const TextStyle(color: Colors.white), // 입력 텍스트는 하얀색 유지
            validator: ValidationUtils.validateEmail,
            enabled: !authProvider.isLoading,
          ),
          const SizedBox(height: AppConstants.spacing),
          TextFormField(
            controller: _passwordController,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: '********',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.white.withOpacity(0.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color:
                      Colors.white.withOpacity(0.5), // visibility 아이콘도 투명도 추가
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: !_isPasswordVisible,
            validator: ValidationUtils.validatePassword,
            enabled: !authProvider.isLoading,
          ),
          const SizedBox(height: AppConstants.spacing),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              const Text(
                '자동 로그인',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacing,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold, // 글자 두께 지정
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppConstants.spacing * 2), // 로그인 버튼과의 간격
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '아직 계정이 없으신가요?',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup'); // 회원가입 화면으로 이동
                },
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: AppConstants.spacing * 2,
            right: AppConstants.spacing * 2,
            top: AppConstants.spacing * 2,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                AppConstants.spacing * 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppConstants.spacing),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'FLick',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: AppConstants.spacing * 2),
              Text(
                '간편 로그인',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing),
              _buildSocialLoginButtons(),
              const SizedBox(height: AppConstants.spacing),
              const _DividerWithText(text: '또는'),
              const SizedBox(height: AppConstants.spacing),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;

  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing,
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
