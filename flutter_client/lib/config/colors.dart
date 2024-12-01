// lib/config/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color.fromARGB(255, 255, 37, 110);
  static const Color secondary = Color(0xFF2196F3);

  // Background Colors
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFCF6679);
  static const Color info = Color(0xFF03A9F4);

  // Resource Colors
  static const Color cpuColor = Color(0xFF2196F3); // Blue
  static const Color memoryColor = Color(0xFF4CAF50); // Green
  static const Color diskColor = Color(0xFF9C27B0); // Purple
  static const Color networkColor = Color(0xFFFF9800); // Orange
  static const Color warningColor = Color(0xFFFF9800);

  // Server Status Colors
  static const Color serverOnline = Color(0xFF4CAF50);
  static const Color serverOffline = Color(0xFFFF5252);
  static const Color serverWarning = Color(0xFFFFB74D);
  static const Color serverCritical = Color(0xFFFF5252);

  // Text Colors
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Colors.white;
  static const Color onSurface = Colors.white;
  static const Color onError = Colors.black;

  // Additional Colors
  static const Color divider = Color(0xFF424242);
  static const Color disabled = Color(0xFF757575);
  static const Color backdrop = Color(0x80000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFFE91E63),
    Color(0xFFF06292),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
  ];

  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF81C784),
  ];

  // Usage Threshold Colors
  static Color getResourceColor(double value) {
    if (value >= 90) return error;
    if (value >= 75) return warning;
    if (value >= 60) return info;
    return success;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return serverOnline;
      case 'offline':
        return serverOffline;
      case 'warning':
        return serverWarning;
      case 'critical':
        return serverCritical;
      default:
        return disabled;
    }
  }
}
