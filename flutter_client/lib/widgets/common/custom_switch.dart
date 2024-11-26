// lib/widgets/common/custom_switch.dart
import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.pink,
      inactiveTrackColor: Colors.grey.withOpacity(0.3),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}
