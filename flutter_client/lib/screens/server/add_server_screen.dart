// lib/screens/server/add_server_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _selectedType = 'Linux';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAddServer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final serverProvider =
          Provider.of<ServerProvider>(context, listen: false);

      // 서버 추가
      await serverProvider.addServer(
        name: _nameController.text,
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
        type: _selectedType,
      );

      if (!mounted) return;

      Navigator.pop(context);
      SnackBarUtils.showSuccess(context, '서버가 추가되었습니다');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, '서버 추가 실패: $e');
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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: '서버 이름',
                  hint: '프로덕션 서버 1',
                  icon: Icons.dns,
                  validator: (value) =>
                      ValidationUtils.validateRequired(value, '서버 이름'),
                ),
                const SizedBox(height: 16),
                _buildDropdownField(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _hostController,
                  label: '호스트',
                  hint: 'example.com 또는 IP 주소',
                  icon: Icons.language,
                  validator: ValidationUtils.validateIpAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _portController,
                  label: '포트',
                  hint: '22',
                  icon: Icons.settings_ethernet,
                  keyboardType: TextInputType.number,
                  validator: ValidationUtils.validatePort,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: '사용자 이름',
                  hint: 'admin',
                  icon: Icons.person_outline,
                  validator: (value) =>
                      ValidationUtils.validateRequired(value, '사용자 이름'),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAddServer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      items: const [
        DropdownMenuItem(value: 'Linux', child: Text('Linux')),
        DropdownMenuItem(value: 'Windows', child: Text('Windows')),
        DropdownMenuItem(value: 'MacOS', child: Text('MacOS')),
      ],
      onChanged: (value) {
        setState(() => _selectedType = value ?? 'Linux');
      },
      decoration: const InputDecoration(
        labelText: '서버 타입',
        prefixIcon: Icon(Icons.computer, color: Colors.grey),
        border: OutlineInputBorder(),
        filled: true,
      ),
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: '비밀번호',
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      style: const TextStyle(color: Colors.white),
      obscureText: !_isPasswordVisible,
      validator: (value) => ValidationUtils.validateRequired(value, '비밀번호'),
    );
  }
}
