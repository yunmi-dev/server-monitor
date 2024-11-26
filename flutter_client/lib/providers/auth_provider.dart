// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_client/services/auth_service.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'package:flutter_client/models/user.dart';
import 'package:flutter_client/utils/error_utils.dart';
import 'package:flutter_client/utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;
  Timer? _sessionTimer;

  User? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastActivityTime;
  bool _biometricsEnabled = false;

  static const sessionTimeout = Duration(minutes: 30);
  static const tokenRefreshInterval = Duration(minutes: 5);

  AuthProvider({
    required AuthService authService,
    required StorageService storageService,
  })  : _authService = authService,
        _storageService = storageService {
    _initialize();
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBiometricsEnabled => _biometricsEnabled;

  Future<void> _initialize() async {
    try {
      _loadSettings();
      final token = await _storageService.getToken();

      if (token != null) {
        _user = await _authService.getCurrentUser();
        _startSessionTimer();
        _updateLastActivityTime();
      }
    } catch (e) {
      logger.error('Auth initialization failed: $e');
      _error = ErrorUtils.getErrorMessage(e);
      await _handleLogout();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    try {
      _biometricsEnabled =
          _storageService.getSetting<bool>('biometrics_enabled') ?? false;
    } catch (e) {
      logger.error('Failed to load auth settings: $e');
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    if (_lastActivityTime != null) {
      final inactiveTime = DateTime.now().difference(_lastActivityTime!);
      if (inactiveTime >= sessionTimeout) {
        logger.info('Session timeout, logging out user');
        await signOut();
      }
    }
  }

  void _updateLastActivityTime() {
    _lastActivityTime = DateTime.now();
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      await _storageService.setSetting('biometrics_enabled', enabled);
      _biometricsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      logger.error('Failed to update biometrics setting: $e');
      throw Exception('Failed to update biometrics setting');
    }
  }

  // Auth Methods
  Future<void> signInWithEmail(String email, String password) async {
    await _handleAuthAction(() async {
      final user = await _authService.signInWithEmail(email, password);
      await _handleSuccessfulAuth(user);
    });
  }

  Future<void> signInWithGoogle() async {
    await _handleAuthAction(() async {
      final user = await _authService.signInWithGoogle();
      await _handleSuccessfulAuth(user);
    });
  }

  Future<void> signInWithApple() async {
    await _handleAuthAction(() async {
      final user = await _authService.signInWithApple();
      await _handleSuccessfulAuth(user);
    });
  }

  Future<void> signInWithKakao() async {
    await _handleAuthAction(() async {
      final user = await _authService.signInWithKakao();
      await _handleSuccessfulAuth(user);
    });
  }

  Future<void> signInWithFacebook() async {
    await _handleAuthAction(() async {
      final user = await _authService.signInWithFacebook();
      await _handleSuccessfulAuth(user);
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _handleAuthAction(() async {
      final user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      await _handleSuccessfulAuth(user);
    });
  }

  Future<void> signOut() async {
    await _handleAuthAction(() async {
      await _authService.signOut();
      await _handleLogout();
    });
  }

  Future<void> _handleLogout() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _user = null;
    _lastActivityTime = null;
    await _storageService.clearToken();
    await _storageService.clearRefreshToken();
  }

  Future<void> resetPassword(String email) async {
    await _handleAuthAction(() async {
      await _authService.resetPassword(email);
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _handleAuthAction(() async {
      await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    Uint8List? profileImage,
  }) async {
    await _handleAuthAction(() async {
      final updatedUser = await _authService.updateProfile(
        name: name,
        email: email,
        profileImage: profileImage,
      );
      _user = updatedUser;
    });
  }

  Future<void> deleteAccount() async {
    await _handleAuthAction(() async {
      await _authService.deleteAccount();
      await _handleLogout();
    });
  }

  Future<void> refreshSession() async {
    if (!isAuthenticated) return;

    try {
      final user = await _authService.getCurrentUser();
      await _handleSuccessfulAuth(user);
    } catch (e) {
      logger.error('Session refresh failed: $e');
      await _handleLogout();
      rethrow;
    }
  }

  Future<void> _handleSuccessfulAuth(User user) async {
    _user = user;
    _updateLastActivityTime();
    _startSessionTimer();
  }

  Future<void> _handleAuthAction(Future<void> Function() action) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await action();
    } catch (e) {
      logger.error('Auth action failed: $e');
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
