// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_client/config/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing * 2),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FLick과 함께하세요',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spacing),
              Text(
                '서버 모니터링을 더 쉽고 효율적으로',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppConstants.spacing * 3),
              _buildSignupForm(),
              const SizedBox(height: AppConstants.spacing * 2),
              _buildTermsCheckbox(),
              const SizedBox(height: AppConstants.spacing * 2),
              _buildSignupButton(),
              const SizedBox(height: AppConstants.spacing),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '이름',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이름을 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacing),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: '이메일',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이메일을 입력해주세요';
            }
            if (!RegExp(AppConstants.emailRegex).hasMatch(value)) {
              return '올바른 이메일 형식이 아닙니다';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacing),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: '비밀번호',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '비밀번호를 입력해주세요';
            }
            if (value.length < AppConstants.minPasswordLength) {
              return '비밀번호는 ${AppConstants.minPasswordLength}자 이상이어야 합니다';
            }
            if (!RegExp(AppConstants.passwordRegex).hasMatch(value)) {
              return '비밀번호는 영문, 숫자, 특수문자를 포함해야 합니다';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spacing),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: '비밀번호 확인',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          obscureText: !_isConfirmPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '비밀번호를 다시 입력해주세요';
            }
            if (value != _passwordController.text) {
              return '비밀번호가 일치하지 않습니다';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '회원가입시 ',
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '이용약관',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Show terms and conditions
                    },
                ),
                const TextSpan(text: '과 '),
                TextSpan(
                  text: '개인정보 처리방침',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Show privacy policy
                    },
                ),
                const TextSpan(text: '에 동의합니다.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _agreedToTerms ? _handleSignup : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacing,
          ),
          disabledBackgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        child: const Text('회원가입'),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '이미 계정이 있으신가요?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            '로그인하기',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSignup() {
    if (_formKey.currentState?.validate() ?? false) {
      // Implement signup logic
    }
  }
}
