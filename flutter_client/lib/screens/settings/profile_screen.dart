// lib/screens/settings/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/utils/validation_utils.dart';
// import 'package:flutter_client/utils/snackbar_utils.dart';
import 'package:flutter_client/widgets/common/confirm_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _showPasswordSection = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final scaffoldContext = ScaffoldMessenger.of(context);
    Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_showPasswordSection) {
        await authProvider.updatePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
      } else {
        await authProvider.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
        );
      }

      if (!mounted) return;

      scaffoldContext.showSnackBar(
        const SnackBar(content: Text('프로필이 업데이트되었습니다.')),
      );

      setState(() {
        _isEditing = false;
        _showPasswordSection = false;
      });
    } catch (e) {
      if (!mounted) return;

      scaffoldContext.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    final navigationContext = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: '계정 삭제',
        content: '정말 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
        confirmText: '삭제',
        isDestructive: true,
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.deleteAccount(_currentPasswordController.text);

      if (!mounted) return;

      navigationContext.pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;

      scaffoldContext.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('프로필'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isEditing = false;
                _showPasswordSection = false;
                _nameController.text = user.name;
                _emailController.text = user.email;
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          color: Colors.white,
                          onPressed: () {
                            // Implement profile image update
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacing * 3),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(user),
                  if (_isEditing) ...[
                    const SizedBox(height: AppConstants.spacing * 2),
                    _buildPasswordSection(),
                    const SizedBox(height: AppConstants.spacing * 2),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(user) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 정보',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: AppConstants.spacing),
          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration(
              label: '이름',
              hint: '홍길동',
              icon: Icons.person_outline,
            ),
            enabled: _isEditing,
            validator: (value) => ValidationUtils.validateRequired(value, '이름'),
          ),
          const SizedBox(height: AppConstants.spacing),
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration(
              label: '이메일',
              hint: 'example@email.com',
              icon: Icons.email_outlined,
            ),
            enabled: _isEditing,
            validator: ValidationUtils.validateEmail,
          ),
          if (!_isEditing) ...[
            const SizedBox(height: AppConstants.spacing),
            _buildInfoRow('가입일', user.createdAt),
            _buildInfoRow('마지막 로그인', user.lastLoginAt),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: _showPasswordSection
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: Center(
        child: TextButton.icon(
          onPressed: () => setState(() => _showPasswordSection = true),
          icon: const Icon(Icons.lock_outline),
          label: const Text('비밀번호 변경'),
        ),
      ),
      secondChild: Container(
        padding: const EdgeInsets.all(AppConstants.spacing),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '비밀번호 변경',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _showPasswordSection = false),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing),
            TextFormField(
              controller: _currentPasswordController,
              decoration: _buildInputDecoration(
                label: '현재 비밀번호',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureCurrentPassword,
                onToggleObscure: () => setState(
                  () => _obscureCurrentPassword = !_obscureCurrentPassword,
                ),
              ),
              obscureText: _obscureCurrentPassword,
              validator: (value) =>
                  ValidationUtils.validateRequired(value, '현재 비밀번호'),
            ),
            const SizedBox(height: AppConstants.spacing),
            TextFormField(
              controller: _newPasswordController,
              decoration: _buildInputDecoration(
                label: '새 비밀번호',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureNewPassword,
                onToggleObscure: () => setState(
                  () => _obscureNewPassword = !_obscureNewPassword,
                ),
              ),
              obscureText: _obscureNewPassword,
              validator: ValidationUtils.validatePassword,
            ),
            const SizedBox(height: AppConstants.spacing),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: _buildInputDecoration(
                label: '새 비밀번호 확인',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleObscure: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) => ValidationUtils.validateConfirmPassword(
                _newPasswordController.text,
                value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacing * 1.5,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('저장'),
          ),
        ),
        const SizedBox(height: AppConstants.spacing),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isLoading ? null : _handleDeleteAccount,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacing * 1.5,
              ),
            ),
            child: const Text(
              '계정 삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleObscure,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscureText! ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggleObscure,
            )
          : null,
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius / 2),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      labelStyle: const TextStyle(color: Colors.grey),
      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
    );
  }
}
