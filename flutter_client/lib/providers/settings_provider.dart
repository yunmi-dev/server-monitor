// lib/providers/settings_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/utils/logger.dart';
import 'package:flutter_client/utils/snackbar_utils.dart';
import 'package:flutter_client/services/navigation_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  Timer? _saveTimer;
  bool _initialized = false;

  // 앱 설정
  ThemeMode _themeMode = ThemeMode.system;
  String _language = AppConstants.defaultLanguage;
  String _timeZone = AppConstants.defaultTimeZone;

  // 알림 설정
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  List<String> _notificationCategories = const ['warning', 'error', 'critical'];

  // 모니터링 설정
  int _dataRefreshInterval = AppConstants.defaultRefreshInterval.inSeconds;
  int _dataRetentionDays = 30;
  double _cpuWarningThreshold = AppConstants.warningThreshold;
  double _memoryWarningThreshold = AppConstants.warningThreshold;
  double _diskWarningThreshold = AppConstants.criticalThreshold;
  bool _autoReconnect = true;
  Duration _reconnectInterval = const Duration(seconds: 5);

  // 차트 설정
  bool _showLegends = true;
  bool _animateCharts = true;
  bool _showGridLines = true;
  String _chartTimeRange = '1h';

  // 방해 금지 모드 설정
  bool _doNotDisturbEnabled = false;
  String _doNotDisturbStart = '22:00';
  String _doNotDisturbEnd = '07:00';
  bool _weekendNotificationsEnabled = true;

  // Getters
  bool get isInitialized => _initialized;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get timeZone => _timeZone;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  List<String> get notificationCategories =>
      List.unmodifiable(_notificationCategories);
  int get dataRefreshInterval => _dataRefreshInterval;
  int get dataRetentionDays => _dataRetentionDays;
  double get cpuWarningThreshold => _cpuWarningThreshold;
  double get memoryWarningThreshold => _memoryWarningThreshold;
  double get diskWarningThreshold => _diskWarningThreshold;
  bool get autoReconnect => _autoReconnect;
  Duration get reconnectInterval => _reconnectInterval;
  bool get showLegends => _showLegends;
  bool get animateCharts => _animateCharts;
  bool get showGridLines => _showGridLines;
  String get chartTimeRange => _chartTimeRange;
  bool get doNotDisturbEnabled => _doNotDisturbEnabled;
  String get doNotDisturbStart => _doNotDisturbStart;
  String get doNotDisturbEnd => _doNotDisturbEnd;
  bool get weekendNotificationsEnabled => _weekendNotificationsEnabled;

  SettingsProvider(this._storage) {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    try {
      final settings = await _storage.getSettings();
      if (settings != null) {
        _applySettings(settings);
      } else {
        _applyDefaultSettings();
      }
    } catch (e) {
      logger.error('Failed to initialize settings: $e');
      _applyDefaultSettings();
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  // Setters with validation and auto-save
  Future<void> setThemeMode(ThemeMode mode) => _updateSetting(
        () => _themeMode = mode,
      );

  Future<void> setLanguage(String languageCode) => _updateSetting(() {
        if (!AppConstants.supportedLanguages.contains(languageCode)) {
          throw ArgumentError('Unsupported language code: $languageCode');
        }
        _language = languageCode;
      });

  Future<void> setTimeZone(String timeZone) => _updateSetting(
        () => _timeZone = timeZone,
      );

  Future<void> setPushNotifications(bool enabled) => _updateSetting(
        () => _pushNotificationsEnabled = enabled,
      );

  Future<void> setEmailNotifications(bool enabled) => _updateSetting(
        () => _emailNotificationsEnabled = enabled,
      );

  Future<void> setSound(bool enabled) => _updateSetting(
        () => _soundEnabled = enabled,
      );

  Future<void> setVibration(bool enabled) => _updateSetting(
        () => _vibrationEnabled = enabled,
      );

  Future<void> setNotificationCategories(List<String> categories) =>
      _updateSetting(
        () => _notificationCategories = List.from(categories),
      );

  Future<void> setDataRefreshInterval(int seconds) => _updateSetting(() {
        if (seconds < 1 || seconds > 60) {
          throw ArgumentError(
              'Refresh interval must be between 1 and 60 seconds');
        }
        _dataRefreshInterval = seconds;
      });

  Future<void> setDataRetentionDays(int days) => _updateSetting(() {
        if (days < 1 || days > 365) {
          throw ArgumentError('Retention days must be between 1 and 365');
        }
        _dataRetentionDays = days;
      });

  Future<void> setCpuWarningThreshold(double threshold) => _updateSetting(() {
        _validateThreshold(threshold);
        _cpuWarningThreshold = threshold;
      });

  Future<void> setMemoryWarningThreshold(double threshold) =>
      _updateSetting(() {
        _validateThreshold(threshold);
        _memoryWarningThreshold = threshold;
      });

  Future<void> setDiskWarningThreshold(double threshold) => _updateSetting(() {
        _validateThreshold(threshold);
        _diskWarningThreshold = threshold;
      });

  Future<void> setAutoReconnect(bool enabled) => _updateSetting(
        () => _autoReconnect = enabled,
      );

  Future<void> setReconnectInterval(Duration interval) => _updateSetting(() {
        if (interval.inSeconds <= 0) {
          throw ArgumentError('Reconnect interval must be positive');
        }
        _reconnectInterval = interval;
      });

  Future<void> setChartSettings({
    bool? showLegends,
    bool? animateCharts,
    bool? showGridLines,
    String? timeRange,
  }) =>
      _updateSetting(() {
        if (showLegends != null) _showLegends = showLegends;
        if (animateCharts != null) _animateCharts = animateCharts;
        if (showGridLines != null) _showGridLines = showGridLines;
        if (timeRange != null) {
          if (!AppConstants.chartTimeRanges.containsKey(timeRange)) {
            throw ArgumentError('Invalid time range: $timeRange');
          }
          _chartTimeRange = timeRange;
        }
      });

  Future<void> setDoNotDisturbEnabled(bool enabled) => _updateSetting(
        () => _doNotDisturbEnabled = enabled,
      );

  Future<void> setDoNotDisturbTime(String timeRange) => _updateSetting(() {
        final times = timeRange.split(' - ');
        if (times.length == 2) {
          _doNotDisturbStart = times[0];
          _doNotDisturbEnd = times[1];
          _doNotDisturbEnabled = true;
        }
      });

  Future<void> setWeekendNotifications(bool enabled) => _updateSetting(
        () => _weekendNotificationsEnabled = enabled,
      );

  void _validateThreshold(double threshold) {
    if (threshold < 0 || threshold > 100) {
      throw ArgumentError('Threshold must be between 0 and 100');
    }
  }

  // 설정 업데이트 유틸리티 메서드
  Future<void> _updateSetting(void Function() updateFn) async {
    try {
      updateFn();
      await _saveSettingsWithDebounce();
      notifyListeners();
    } catch (e) {
      logger.error('Failed to update setting: $e');
      rethrow;
    }
  }

  // 디바운스 적용된 설정 저장
  Future<void> _saveSettingsWithDebounce() async {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _saveSettingsToStorage();
      } catch (e) {
        logger.error('Failed to save settings: $e');
        // NavigationService 사용
        if (NavigationService.context != null) {
          SnackBarUtils.showError(
            NavigationService.context!,
            '설정 저장 실패: ${e.toString()}',
          );
        }
        rethrow;
      }
    });
  }

  Future<void> _saveSettingsToStorage() async {
    final settings = {
      'themeMode': _themeMode.index,
      'language': _language,
      'timeZone': _timeZone,
      'pushNotifications': _pushNotificationsEnabled,
      'emailNotifications': _emailNotificationsEnabled,
      'sound': _soundEnabled,
      'vibration': _vibrationEnabled,
      'notificationCategories': _notificationCategories,
      'dataRefreshInterval': _dataRefreshInterval,
      'dataRetentionDays': _dataRetentionDays,
      'cpuWarningThreshold': _cpuWarningThreshold,
      'memoryWarningThreshold': _memoryWarningThreshold,
      'diskWarningThreshold': _diskWarningThreshold,
      'autoReconnect': _autoReconnect,
      'reconnectInterval': _reconnectInterval.inSeconds,
      'showLegends': _showLegends,
      'animateCharts': _animateCharts,
      'showGridLines': _showGridLines,
      'chartTimeRange': _chartTimeRange,
    };

    await _storage.saveSettings(settings);
  }

  void _applySettings(Map<String, dynamic> settings) {
    _themeMode =
        ThemeMode.values[settings['themeMode'] ?? ThemeMode.system.index];
    _language = settings['language'] ?? AppConstants.defaultLanguage;
    _timeZone = settings['timeZone'] ?? AppConstants.defaultTimeZone;
    _pushNotificationsEnabled = settings['pushNotifications'] ?? true;
    _emailNotificationsEnabled = settings['emailNotifications'] ?? true;
    _soundEnabled = settings['sound'] ?? true;
    _vibrationEnabled = settings['vibration'] ?? true;
    _notificationCategories = List<String>.from(
        settings['notificationCategories'] ?? ['warning', 'error', 'critical']);
    _dataRefreshInterval = settings['dataRefreshInterval'] ??
        AppConstants.defaultRefreshInterval.inSeconds;
    _dataRetentionDays = settings['dataRetentionDays'] ?? 30;
    _cpuWarningThreshold =
        (settings['cpuWarningThreshold'] ?? AppConstants.warningThreshold)
            .toDouble();
    _memoryWarningThreshold =
        (settings['memoryWarningThreshold'] ?? AppConstants.warningThreshold)
            .toDouble();
    _diskWarningThreshold =
        (settings['diskWarningThreshold'] ?? AppConstants.criticalThreshold)
            .toDouble();
    _autoReconnect = settings['autoReconnect'] ?? true;
    _reconnectInterval = Duration(
      seconds: settings['reconnectInterval'] ?? 5,
    );
    _showLegends = settings['showLegends'] ?? true;
    _animateCharts = settings['animateCharts'] ?? true;
    _showGridLines = settings['showGridLines'] ?? true;
    _chartTimeRange = settings['chartTimeRange'] ?? '1h';
    _doNotDisturbEnabled = settings['doNotDisturbEnabled'] ?? false;
    _doNotDisturbStart = settings['doNotDisturbStart'] ?? '22:00';
    _doNotDisturbEnd = settings['doNotDisturbEnd'] ?? '07:00';
    _weekendNotificationsEnabled = settings['weekendNotifications'] ?? true;
  }

  void _applyDefaultSettings() {
    _themeMode = ThemeMode.system;
    _language = AppConstants.defaultLanguage;
    _timeZone = AppConstants.defaultTimeZone;
    _pushNotificationsEnabled = true;
    _emailNotificationsEnabled = true;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _notificationCategories = ['warning', 'error', 'critical'];
    _dataRefreshInterval = AppConstants.defaultRefreshInterval.inSeconds;
    _dataRetentionDays = 30;
    _cpuWarningThreshold = AppConstants.warningThreshold;
    _memoryWarningThreshold = AppConstants.warningThreshold;
    _diskWarningThreshold = AppConstants.criticalThreshold;
    _autoReconnect = true;
    _reconnectInterval = const Duration(seconds: 5);
    _showLegends = true;
    _animateCharts = true;
    _showGridLines = true;
    _chartTimeRange = '1h';
    _doNotDisturbEnabled = false;
    _doNotDisturbStart = '22:00';
    _doNotDisturbEnd = '07:00';
    _weekendNotificationsEnabled = true;
  }

  Future<void> resetToDefaults() async {
    try {
      _applyDefaultSettings();
      await _saveSettingsToStorage();
      notifyListeners();
    } catch (e) {
      logger.error('Failed to reset settings: $e');
      rethrow;
    }
  }

  // 설정 내보내기/가져오기
  Map<String, dynamic> exportSettings() {
    return {
      'themeMode': _themeMode.index,
      'language': _language,
      'timeZone': _timeZone,
      'pushNotifications': _pushNotificationsEnabled,
      'emailNotifications': _emailNotificationsEnabled,
      'sound': _soundEnabled,
      'vibration': _vibrationEnabled,
      'notificationCategories': _notificationCategories,
      'dataRefreshInterval': _dataRefreshInterval,
      'dataRetentionDays': _dataRetentionDays,
      'cpuWarningThreshold': _cpuWarningThreshold,
      'memoryWarningThreshold': _memoryWarningThreshold,
      'diskWarningThreshold': _diskWarningThreshold,
      'autoReconnect': _autoReconnect,
      'reconnectInterval': _reconnectInterval.inSeconds,
      'showLegends': _showLegends,
      'animateCharts': _animateCharts,
      'showGridLines': _showGridLines,
      'chartTimeRange': _chartTimeRange,
      'doNotDisturbEnabled': _doNotDisturbEnabled,
      'doNotDisturbStart': _doNotDisturbStart,
      'doNotDisturbEnd': _doNotDisturbEnd,
      'weekendNotifications': _weekendNotificationsEnabled,
    };
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      _applySettings(settings);
      await _saveSettingsToStorage();
      notifyListeners();
    } catch (e) {
      logger.error('Failed to import settings: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
