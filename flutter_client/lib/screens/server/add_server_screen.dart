// lib/screens/server/add_server_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/utils/validation_utils.dart';
import 'package:flutter_client/utils/snackbar_utils.dart';
import 'package:flutter_client/config/constants.dart';

class ServerAddScreen extends StatefulWidget {
  const ServerAddScreen({super.key});

  @override
  State<ServerAddScreen> createState() => _ServerAddScreenState();
}

class _ServerAddScreenState extends State<ServerAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  ServerType _selectedType = ServerType.linux;
  ServerCategory _selectedCategory = ServerCategory.physical;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleAddServer() async {
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
        category: _selectedCategory,
      );

      if (!mounted) return;
      Navigator.pop(context);
      SnackBarUtils.showSuccess(context, '서버가 추가되었습니다');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, '서버 추가 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                label: '서버 이름',
                icon: Icons.dns,
                validator: ValidationUtils.validateServerName,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ServerType>(
                value: _selectedType,
                items: AppConstants.serverTypeItems,
                onChanged: (value) =>
                    setState(() => _selectedType = value ?? ServerType.linux),
                decoration: _getInputDecoration('운영체제', Icons.computer),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ServerCategory>(
                value: _selectedCategory,
                items: AppConstants.serverCategoryItems,
                onChanged: (value) => setState(
                    () => _selectedCategory = value ?? ServerCategory.physical),
                decoration: _getInputDecoration('서버 유형', Icons.category),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _hostController,
                label: '호스트',
                icon: Icons.language,
                validator: ValidationUtils.validateHost,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _portController,
                label: '포트',
                icon: Icons.settings_ethernet,
                keyboardType: TextInputType.number,
                validator: ValidationUtils.validatePort,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _usernameController,
                label: '사용자 이름',
                icon: Icons.person,
                validator: (v) => ValidationUtils.validateRequired(v, '사용자 이름'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _getInputDecoration('비밀번호', Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (v) => ValidationUtils.validateRequired(v, '비밀번호'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddServer,
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('서버 추가'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _getInputDecoration(label, icon),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.grey[900],
    );
  }
}
