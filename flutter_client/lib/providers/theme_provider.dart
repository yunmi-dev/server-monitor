// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  ThemeMode _themeMode;

  ThemeProvider(this._storageService) : _themeMode = ThemeMode.system {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    try {
      final savedMode = _storageService.getSettingValue<int>(
        'theme_mode',
        defaultValue: ThemeMode.system.index,
      );
      _themeMode = ThemeMode.values[savedMode ?? ThemeMode.system.index];
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme mode: $e');
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    try {
      await _storageService.setSettingValue('theme_mode', mode.index);
      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return MediaQueryData.fromView(WidgetsBinding.instance.window)
              .platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
