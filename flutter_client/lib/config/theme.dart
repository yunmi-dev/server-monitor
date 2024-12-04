// lib/config/theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF4099), // Main Color (FFC0DE)
        secondary: Color(0xFFFFC0DE), // Accent Color (FF4099)
        surface: Color(0xFF121212), // Background (121212)
        error: Color(0xFFCF6679), // Error Color
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212), // Background Color
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E), // 카드 배경 색상
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212), // Match background
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white, // AppBar text/icon color
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        buttonColor: const Color(0xFFFF4099), // Button Main Color
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4099), // Button Main Color
          foregroundColor: Colors.white,
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
          borderSide: const BorderSide(
            color: Color(0xFFFF4099),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: const BorderSide(
            color: Color(0xFFFF4099),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: const BorderSide(
            color: Color(0xFFFF4099),
            width: 2,
          ),
        ),
        // 에러 상태일 때의 테두리
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: const BorderSide(
            color: Color(0xFFFF4099),
            width: 1,
          ),
        ),
        // 에러 상태에서 포커스될 때의 테두리
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          borderSide: const BorderSide(
            color: Color(0xFFFF4099),
            width: 2,
          ),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF4099),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFFF4099),
        ),
        hintStyle: TextStyle(
          color: const Color(0xFFFF4099).withOpacity(0.7),
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
            return const Color.fromARGB(255, 247, 112, 175);
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color.fromARGB(255, 247, 112, 175).withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color.fromARGB(255, 247, 112, 175),
        inactiveTrackColor: Colors.grey,
        thumbColor: Color.fromARGB(255, 247, 112, 175),
        overlayColor: Color(0x29E91E63),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        disabledColor: Colors.grey.withOpacity(0.1),
        selectedColor:
            const Color.fromARGB(255, 247, 112, 175).withOpacity(0.2),
        secondarySelectedColor:
            const Color.fromARGB(255, 247, 112, 175).withOpacity(0.2),
        padding: const EdgeInsets.all(AppConstants.spacing / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color.fromARGB(255, 247, 112, 175),
      ),
    );
  }
}
