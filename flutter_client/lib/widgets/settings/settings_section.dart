// lib/widgets/settings/settings_section.dart
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final Color backgroundColor;
  final TextStyle? titleStyle;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              title!,
              style: titleStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
