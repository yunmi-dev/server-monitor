// lib/widgets/server/add_server_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/utils/validation_utils.dart';
import 'package:flutter_client/config/constants.dart';

class AddServerModal extends StatefulWidget {
  final Function(String name, String host, int port, String username,
      String password, ServerType type, ServerCategory category) onAdd;

  const AddServerModal({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddServerModal> createState() => _AddServerModalState();
}

class _AddServerModalState extends State<AddServerModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  ServerType _selectedType = ServerType.linux;
  ServerCategory _selectedCategory = ServerCategory.physical;

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
      final port = int.tryParse(_portController.text);
      if (port == null) throw Exception('Invalid port number');

      await widget.onAdd(
        _nameController.text.trim(),
        _hostController.text.trim(),
        port,
        _usernameController.text.trim(),
        _passwordController.text,
        _selectedType,
        _selectedCategory,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Server',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Server Name',
                icon: Icons.dns_outlined,
                validator: ValidationUtils.validateServerName,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hostController,
                label: 'Host',
                icon: Icons.language_outlined,
                validator: ValidationUtils.validateHost,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _portController,
                label: 'Port',
                icon: Icons.numbers_outlined,
                keyboardType: TextInputType.number,
                validator: ValidationUtils.validatePort,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.person_outline,
                validator: (value) =>
                    ValidationUtils.validateRequired(value, 'Username'),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(),
              const SizedBox(height: 12),
              _buildDropdownField(
                value: _selectedType,
                items: AppConstants.serverTypeItems,
                label: '운영체제',
                icon: Icons.computer_outlined,
                onChanged: (value) =>
                    setState(() => _selectedType = value ?? ServerType.linux),
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                value: _selectedCategory,
                items: AppConstants.serverCategoryItems,
                label: '서버 유형',
                icon: Icons.category_outlined,
                onChanged: (value) => setState(
                    () => _selectedCategory = value ?? ServerCategory.physical),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAddServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add'),
                  ),
                ],
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
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (value) => ValidationUtils.validateRequired(value, 'Password'),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon:
            Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.5)),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withOpacity(0.5),
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required String label,
    required IconData icon,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        color: Colors.white.withOpacity(0.1),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }
}
