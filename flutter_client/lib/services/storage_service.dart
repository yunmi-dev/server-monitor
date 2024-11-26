// lib/services/storage_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_client/utils/logger.dart';
import 'dart:async';

class StorageService {
  static StorageService? _instance;
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final PackageInfo _packageInfo;

  // 보안 저장소 키
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  // 일반 저장소 키
  static const String _firstLaunchKey = 'first_launch';
  static const String _lastVersionKey = 'last_version';
  static const String _lastLoginKey = 'last_login';

  StorageService._({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
    required PackageInfo packageInfo,
  })  : _prefs = prefs,
        _secureStorage = secureStorage,
        _packageInfo = packageInfo;

  static Future<StorageService> initialize() async {
    if (_instance != null) return _instance!;

    try {
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      final packageInfo = await PackageInfo.fromPlatform();

      _instance = StorageService._(
        prefs: prefs,
        secureStorage: secureStorage,
        packageInfo: packageInfo,
      );

      await _instance!._handleAppLaunch();
      return _instance!;
    } catch (e) {
      logger.error('Failed to initialize StorageService: $e');
      rethrow;
    }
  }

  // 토큰 관리
  Future<void> setToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      logger.error('Failed to save token: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      logger.error('Failed to get token: $e');
      return null;
    }
  }

  Future<void> setRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      logger.error('Failed to save refresh token: $e');
      rethrow;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      logger.error('Failed to get refresh token: $e');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      logger.error('Failed to clear token: $e');
      rethrow;
    }
  }

  Future<void> clearRefreshToken() async {
    try {
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      logger.error('Failed to clear refresh token: $e');
      rethrow;
    }
  }

  // 유저 데이터 관리
  Future<void> setUserData(Map<String, dynamic> userData) async {
    try {
      final encodedData = json.encode(userData);
      await _secureStorage.write(key: _userDataKey, value: encodedData);
    } catch (e) {
      logger.error('Failed to save user data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final encodedData = await _secureStorage.read(key: _userDataKey);
      if (encodedData == null) return null;
      return json.decode(encodedData) as Map<String, dynamic>;
    } catch (e) {
      logger.error('Failed to get user data: $e');
      return null;
    }
  }

  Future<void> clearUserData() async {
    try {
      await _secureStorage.delete(key: _userDataKey);
    } catch (e) {
      logger.error('Failed to clear user data: $e');
      rethrow;
    }
  }

  // 설정 관리
  Future<void> setSetting<T>(String key, T value) async {
    try {
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(key, value);
      } else {
        throw UnsupportedError(
            'Unsupported type for settings: ${value.runtimeType}');
      }
    } catch (e) {
      logger.error('Failed to save setting "$key": $e');
      rethrow;
    }
  }

  T? getSetting<T>(String key) {
    try {
      return _prefs.get(key) as T?;
    } catch (e) {
      logger.error('Failed to get setting "$key": $e');
      return null;
    }
  }

  Future<void> removeSetting(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e) {
      logger.error('Failed to remove setting "$key": $e');
      rethrow;
    }
  }

  // 앱 상태 관리
  Future<void> _handleAppLaunch() async {
    try {
      final isFirstLaunch = !_prefs.containsKey(_firstLaunchKey);
      if (isFirstLaunch) {
        await _prefs.setBool(_firstLaunchKey, false);
      }

      final lastVersion = _prefs.getString(_lastVersionKey);
      final currentVersion = _packageInfo.version;
      if (lastVersion != currentVersion) {
        await _prefs.setString(_lastVersionKey, currentVersion);
        // 여기서 버전 업데이트 로직 추가 가능
      }

      await _prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    } catch (e) {
      logger.error('Failed to handle app launch: $e');
    }
  }

  bool get isFirstLaunch => _prefs.getBool(_firstLaunchKey) ?? true;
  String get currentVersion => _packageInfo.version;
  String get lastVersion => _prefs.getString(_lastVersionKey) ?? '';
  DateTime? get lastLogin {
    final dateStr = _prefs.getString(_lastLoginKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  // 전체 초기화
  Future<void> clearAll() async {
    try {
      await Future.wait([
        _secureStorage.deleteAll(),
        _prefs.clear(),
      ]);
    } catch (e) {
      logger.error('Failed to clear all storage: $e');
      rethrow;
    }
  }

  // 설정 저장을 위한 키
  static const String _settingsKey = 'app_settings';
  static const Duration _settingsSaveDelay = Duration(milliseconds: 500);
  Timer? _saveDebounceTimer;

  // 모든 설정 가져오기
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final allSettings = <String, dynamic>{};

      // 일반 설정 가져오기
      final settingsJson = _prefs.getString(_settingsKey);
      if (settingsJson != null) {
        allSettings.addAll(json.decode(settingsJson));
      }

      // 보안 설정 가져오기 (필요한 경우)
      final secureSettingsJson =
          await _secureStorage.read(key: '${_settingsKey}_secure');
      if (secureSettingsJson != null) {
        allSettings.addAll(json.decode(secureSettingsJson));
      }

      return allSettings.isNotEmpty ? allSettings : null;
    } catch (e) {
      logger.error('Failed to get settings: $e');
      return null;
    }
  }

  // 모든 설정 저장하기
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_settingsSaveDelay, () async {
      try {
        // 일반 설정과 보안 설정 분리
        final secureSettings = <String, dynamic>{};
        final normalSettings = <String, dynamic>{};

        settings.forEach((key, value) {
          if (_isSecureSetting(key)) {
            secureSettings[key] = value;
          } else {
            normalSettings[key] = value;
          }
        });

        // 일반 설정 저장
        if (normalSettings.isNotEmpty) {
          await _prefs.setString(_settingsKey, json.encode(normalSettings));
        }

        // 보안 설정 저장
        if (secureSettings.isNotEmpty) {
          await _secureStorage.write(
            key: '${_settingsKey}_secure',
            value: json.encode(secureSettings),
          );
        }

        logger.info('Settings saved successfully');
      } catch (e) {
        logger.error('Failed to save settings: $e');
        rethrow;
      }
    });
  }

  // 특정 설정이 보안 설정인지 확인
  bool _isSecureSetting(String key) {
    const secureKeys = [
      'auth_token',
      'refresh_token',
      'api_key',
      'credentials',
      // 추가 보안 설정 키들...
    ];
    return secureKeys.contains(key);
  }

  // 설정 초기화
  Future<void> clearSettings() async {
    try {
      await Future.wait([
        _prefs.remove(_settingsKey),
        _secureStorage.delete(key: '${_settingsKey}_secure'),
      ]);
      logger.info('Settings cleared successfully');
    } catch (e) {
      logger.error('Failed to clear settings: $e');
      rethrow;
    }
  }

  // 특정 설정 값 가져오기
  T? getSettingValue<T>(String key, {T? defaultValue}) {
    try {
      final settings = _prefs.getString(_settingsKey);
      if (settings == null) return defaultValue;

      final decoded = json.decode(settings) as Map<String, dynamic>;
      final value = decoded[key];

      if (value == null) return defaultValue;

      // 타입 체크 및 변환
      if (T == int && value is num) {
        return value.toInt() as T;
      } else if (T == double && value is num) {
        return value.toDouble() as T;
      } else if (value is T) {
        return value;
      }

      return defaultValue;
    } catch (e) {
      logger.error('Failed to get setting value for "$key": $e');
      return defaultValue;
    }
  }

  // 특정 설정 값 저장하기
  Future<void> setSettingValue<T>(String key, T value) async {
    try {
      final settings = await getSettings() ?? {};
      settings[key] = value;
      await saveSettings(settings);
    } catch (e) {
      logger.error('Failed to set setting value for "$key": $e');
      rethrow;
    }
  }

  // 설정 마이그레이션 지원
  Future<void> migrateSettings(String fromVersion, String toVersion) async {
    try {
      final settings = await getSettings();
      if (settings == null) return;

      // 버전별 마이그레이션 로직
      switch (fromVersion) {
        case "1.0.0":
          // 1.0.0 -> 2.0.0 마이그레이션
          if (toVersion.startsWith("2.")) {
            // 설정 구조 변경 등의 마이그레이션 작업
            settings['migrated_from'] = fromVersion;
            await saveSettings(settings);
          }
          break;
        // 추가 버전 마이그레이션 케이스들...
      }

      logger.info('Settings migrated from $fromVersion to $toVersion');
    } catch (e) {
      logger.error('Failed to migrate settings: $e');
      rethrow;
    }
  }
}
