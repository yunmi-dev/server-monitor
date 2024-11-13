// lib/features/settings/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  bool _isLoading = false;
  String? _error;

  // 설정 키
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyCriticalAlertsOnly = 'critical_alerts_only';
  static const String _keyRefreshInterval = 'refresh_interval';
  static const String _keyDarkMode = 'dark_mode';

  SettingsProvider(this._prefs);

  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;
  bool get criticalAlertsOnly =>
      _prefs.getBool(_keyCriticalAlertsOnly) ?? false;
  int get refreshInterval => _prefs.getInt(_keyRefreshInterval) ?? 30;
  bool get darkMode => _prefs.getBool(_keyDarkMode) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_keyNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setCriticalAlertsOnly(bool value) async {
    await _prefs.setBool(_keyCriticalAlertsOnly, value);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int seconds) async {
    await _prefs.setInt(_keyRefreshInterval, seconds);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }
}
