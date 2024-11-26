// lib/config/theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE91E63), // Pink
        secondary: Color(0xFF2196F3), // Blue
        surface: Color(0xFF1E1E1E), // 아니면 Color(0xFF121212)
        error: Color(0xFFCF6679), // Pink-Red
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        buttonColor: const Color(0xFFE91E63),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing * 2,
            vertical: AppConstants.spacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: const BorderSide(
            color: Color(0xFFE91E63),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: const BorderSide(
            color: Color(0xFFCF6679),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.spacing),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: AppConstants.iconSize,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE91E63);
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE91E63).withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFFE91E63),
        inactiveTrackColor: Colors.grey,
        thumbColor: Color(0xFFE91E63),
        overlayColor: Color(0x29E91E63),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        disabledColor: Colors.grey.withOpacity(0.1),
        selectedColor: const Color(0xFFE91E63).withOpacity(0.2),
        secondarySelectedColor: const Color(0xFFE91E63).withOpacity(0.2),
        padding: const EdgeInsets.all(AppConstants.spacing / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFE91E63),
      ),
    );
  }
}
