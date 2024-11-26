// lib/screens/server/server_add_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/utils/validation_utils.dart';
import 'package:flutter_client/utils/snackbar_utils.dart';

class ServerAddScreen extends StatefulWidget {
  const ServerAddScreen({super.key});

  @override
  State<ServerAddScreen> createState() => _ServerAddScreenState();
}

class _ServerAddScreenState extends State<ServerAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _selectedType = 'Linux';

  final List<String> _serverTypes = ['Linux', 'Windows', 'MacOS'];

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final serverProvider =
          Provider.of<ServerProvider>(context, listen: false);
      await serverProvider.addServer(
        name: _nameController.text,
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
        type: _selectedType,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, '서버가 추가되었습니다.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
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
        title: const Text('서버 추가'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.defaultPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: '기본 정보',
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration(
                        label: '서버 이름',
                        hint: '프로덕션 서버 1',
                        icon: Icons.dns,
                      ),
                      validator: (value) =>
                          ValidationUtils.validateRequired(value, '서버 이름'),
                    ),
                    const SizedBox(height: AppConstants.spacing),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: _buildInputDecoration(
                        label: '서버 타입',
                        icon: Icons.computer,
                      ),
                      items: _serverTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing * 2),
                _buildSection(
                  title: '연결 정보',
                  children: [
                    TextFormField(
                      controller: _hostController,
                      decoration: _buildInputDecoration(
                        label: '호스트',
                        hint: 'example.com 또는 IP 주소',
                        icon: Icons.language,
                      ),
                      validator: ValidationUtils.validateIpAddress,
                    ),
                    const SizedBox(height: AppConstants.spacing),
                    TextFormField(
                      controller: _portController,
                      decoration: _buildInputDecoration(
                        label: '포트',
                        hint: '22',
                        icon: Icons.settings_ethernet,
                      ),
                      keyboardType: TextInputType.number,
                      validator: ValidationUtils.validatePort,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing * 2),
                _buildSection(
                  title: '인증 정보',
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: _buildInputDecoration(
                        label: '사용자 이름',
                        hint: 'admin',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) =>
                          ValidationUtils.validateRequired(value, '사용자 이름'),
                    ),
                    const SizedBox(height: AppConstants.spacing),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _buildInputDecoration(
                        label: '비밀번호',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) =>
                          ValidationUtils.validateRequired(value, '비밀번호'),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacing * 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                        : const Text('서버 추가'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: AppConstants.spacing),
        Container(
          padding: const EdgeInsets.all(AppConstants.spacing),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      suffixIcon: suffixIcon,
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
