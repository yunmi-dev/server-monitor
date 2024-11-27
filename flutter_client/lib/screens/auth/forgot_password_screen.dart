// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/utils/validation_utils.dart';
import 'package:flutter_client/utils/snackbar_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _submitted = false;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resetPassword(_emailController.text);

      if (!mounted) return;

      setState(() => _submitted = true);

      // 성공 메시지
      SnackBarUtils.showSuccess(
        context,
        '비밀번호 재설정 이메일이 발송되었습니다.\n이메일을 확인해주세요.',
      );

      // 3초 후 자동으로 로그인 화면으로 이동
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;

      SnackBarUtils.showError(
        context,
        '이메일 발송에 실패했습니다.\n잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('비밀번호 찾기'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spacing * 2),
              Text(
                '이메일 주소를 입력해주세요',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing),
              Text(
                '가입하신 이메일 주소로 비밀번호 재설정 링크를 보내드립니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing * 3),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '이메일',
                        hintText: 'your@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.cardBorderRadius,
                          ),
                        ),
                        enabled: !_isLoading && !_submitted,
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSubmit(),
                      validator: ValidationUtils.validateEmail,
                      enabled: !_isLoading && !_submitted,
                    ),
                    const SizedBox(height: AppConstants.spacing * 3),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading || _submitted) ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.spacing * 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardBorderRadius,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : _submitted
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline),
                                      SizedBox(width: 8),
                                      Text('이메일 발송 완료'),
                                    ],
                                  )
                                : const Text('비밀번호 재설정 이메일 받기'),
                      ),
                    ),
                    if (_submitted) ...[
                      const SizedBox(height: AppConstants.spacing * 2),
                      const Text(
                        '이메일이 도착하지 않았나요?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: const Text('다시 보내기'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
