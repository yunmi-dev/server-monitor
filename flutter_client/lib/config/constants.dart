// lib/config/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  // API Endpoints
  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String wsUrl = 'ws://localhost:8080/api/v1/ws';

  // Authentication
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const Duration tokenExpiry = Duration(hours: 24);
  static const Duration sessionTimeout = Duration(minutes: 30);

  // Language Settings
  static const String defaultLanguage = 'ko';
  static const String defaultTimeZone = 'Asia/Seoul';
  static const List<String> supportedLanguages = ['ko', 'en', 'ja', 'zh'];
  static const Map<String, String> languageNames = {
    'ko': '한국어',
    'en': 'English',
    'ja': '日本語',
    'zh': '中文',
  };

  // 테스트용 더미 계정
  static const Map<String, String> dummyAccounts = {
    'abc123@naver.com': 'aabbcc123!',
    'abc123@gmail.com': 'aabbcc123!',
  };

  // Theme Settings
  static const Map<ThemeMode, String> themeModeNames = {
    ThemeMode.system: '시스템 설정',
    ThemeMode.light: '라이트 모드',
    ThemeMode.dark: '다크 모드',
  };

  // Monitoring Settings
  static const Duration defaultRefreshInterval = Duration(seconds: 5);
  static const Duration defaultReconnectInterval = Duration(seconds: 5);
  static const Duration chartAnimationDuration = Duration(milliseconds: 300);
  static const int defaultDataRetentionDays = 30;
  static const int maxDataPoints = 60;
  static const double warningThreshold = 80.0;
  static const double criticalThreshold = 90.0;

  // Chart Settings
  static const Map<String, Duration> chartTimeRanges = {
    '1h': Duration(hours: 1),
    '6h': Duration(hours: 6),
    '12h': Duration(hours: 12),
    '24h': Duration(hours: 24),
    '7d': Duration(days: 7),
    '30d': Duration(days: 30),
  };

  static const List<String> chartColors = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FFC107', // Amber
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
  ];

  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double spacing = 16.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);

  // Default Settings Map
  static const Map<String, dynamic> defaultSettings = {
    'themeMode': ThemeMode.system,
    'language': defaultLanguage,
    'timeZone': defaultTimeZone,
    'pushNotifications': true,
    'emailNotifications': true,
    'sound': true,
    'vibration': true,
    'notificationCategories': ['warning', 'error', 'critical'],
    'dataRefreshInterval': 5,
    'dataRetentionDays': 30,
    'cpuWarningThreshold': warningThreshold,
    'memoryWarningThreshold': warningThreshold,
    'diskWarningThreshold': criticalThreshold,
    'autoReconnect': true,
    'reconnectInterval': defaultReconnectInterval,
    'showLegends': true,
    'animateCharts': true,
    'showGridLines': true,
    'chartTimeRange': '1h',
  };

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const String passwordRegex =
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$';
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // File Size Limits
  static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxExportFileSize = 50 * 1024 * 1024; // 50MB

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const Map<String, String> relativeDateFormats = {
    'today': '오늘',
    'yesterday': '어제',
    'tomorrow': '내일',
    'thisWeek': '이번 주',
    'lastWeek': '지난 주',
    'thisMonth': '이번 달',
    'lastMonth': '지난 달',
  };

  // Error Messages
  static const String networkError = '네트워크 연결을 확인해주세요.';
  static const String serverError = '서버 오류가 발생했습니다.';
  static const String authError = '인증에 실패했습니다.';
  static const String unknownError = '알 수 없는 오류가 발생했습니다.';
  static const String timeoutError = '요청 시간이 초과되었습니다.';
  static const String validationError = '입력값을 확인해주세요.';

  // Success Messages
  static const String loginSuccess = '로그인 되었습니다.';
  static const String logoutSuccess = '로그아웃 되었습니다.';
  static const String settingsSaved = '설정이 저장되었습니다.';
  static const String updateSuccess = '업데이트가 완료되었습니다.';
  static const String deleteSuccess = '삭제가 완료되었습니다.';

  // Alert Types
  static const Set<String> alertTypes = {
    'info',
    'warning',
    'error',
    'critical',
    'success',
  };

  // Cache Settings
  static const Duration defaultCacheDuration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Rate Limiting
  static const Duration throttleInterval = Duration(milliseconds: 500);
  static const int maxRequestsPerMinute = 60;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Miscellaneous
  static const String appName = 'Server Monitor';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String supportEmail = 'support@example.com';
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
}
