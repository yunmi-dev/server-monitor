// lib/widgets/settings/language_selection_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/settings_provider.dart';

class LanguageSelectionSheet extends StatelessWidget {
  const LanguageSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Select Language',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildLanguageItem(context, 'English', 'en'),
                    _buildLanguageItem(context, '한국어', 'ko'),
                    _buildLanguageItem(context, '日本語', 'ja'),
                    _buildLanguageItem(context, 'Español', 'es'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(BuildContext context, String label, String code) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isSelected = settings.language == code;
        return ListTile(
          title: Text(label),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () {
            settings.setLanguage(code);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
