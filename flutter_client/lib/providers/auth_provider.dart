// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_client/services/auth_service.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'package:flutter_client/models/user.dart';
import 'package:flutter_client/utils/error_utils.dart';
import 'package:flutter_client/utils/logger.dart';
import 'package:flutter_client/models/auth_result.dart';
import 'package:flutter_client/models/auth_result.dart' as models;

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;
  Timer? _sessionTimer;

  User? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastActivityTime;

  static const sessionTimeout = Duration(minutes: 30);
  static const tokenRefreshInterval = Duration(minutes: 5);

  AuthProvider({
    required AuthService authService,
    required StorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize method added here
  Future<void> initialize() async {
    try {
      final token = await _storageService.getToken();
      final refreshTokenStr = await _storageService.getRefreshToken();

      if (token != null && refreshTokenStr != null) {
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

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSession();
    });
  }

  Future<void> refreshSession() async {
    if (!isAuthenticated) return;

    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null) return;

    try {
      final authResult = await _authService.refreshToken(refreshToken);
      _user = authResult.user;
      await _storageService.setToken(authResult.accessToken);
      await _storageService.setRefreshToken(authResult.refreshToken);
      _updateLastActivityTime();
      _startSessionTimer();
    } catch (e) {
      logger.error('Session refresh failed: $e');
      await _handleLogout();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    await _handleAuthAction(() async {
      final authResult = await _authService.signInWithGoogle();
      _user = authResult.user;
      await _storageService.setToken(authResult.accessToken);
      await _storageService.setRefreshToken(authResult.refreshToken);
      _updateLastActivityTime();
      _startSessionTimer();
    });
  }

  Future<void> signInWithApple() async {
    await _handleAuthAction(() async {
      final authResult = await _authService.signInWithApple();
      _user = authResult.user;
      await _storageService.setToken(authResult.accessToken);
      await _storageService.setRefreshToken(authResult.refreshToken);
      _updateLastActivityTime();
      _startSessionTimer();
    });
  }

  Future<void> signInWithKakao() async {
    await _handleAuthAction(() async {
      final authResult = await _authService.signInWithKakao();
      _user = authResult.user;
      await _storageService.setToken(authResult.accessToken);
      await _storageService.setRefreshToken(authResult.refreshToken);
      _updateLastActivityTime();
      _startSessionTimer();
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _handleAuthAction(() async {
      final authResult = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      _user = authResult.user;
      await _storageService.setToken(authResult.accessToken);
      await _storageService.setRefreshToken(authResult.refreshToken);
      _updateLastActivityTime();
      _startSessionTimer();
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

  // Auth Methods
  Future<void> signInWithEmail(String email, String password) async {
    await _handleAuthAction(() async {
      final authResult = await _authService.signInWithEmail(email, password);
      _user = authResult.user;
      await _storageService.setToken(authResult.accessToken);
      await _storageService.setRefreshToken(authResult.refreshToken);
      _updateLastActivityTime();
      _startSessionTimer();
    });
  }

  Future<void> signInWithFacebook() async {
    await _handleAuthAction(() async {
      final authResult = await _authService.signInWithFacebook();
      _user = authResult.user;
      await _storageService.setToken(authResult.accessToken);
      await _storageService.setRefreshToken(authResult.refreshToken);
      _updateLastActivityTime();
      _startSessionTimer();
    });
  }

  Future<void> signOut() async {
    await _handleAuthAction(() async {
      await _authService.signOut();
      await _handleLogout();
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

  Future<void> deleteAccount({String? password}) async {
    await _handleAuthAction(() async {
      await _authService.deleteAccount(password: password);
      await _handleLogout();
    });
  }

  Future<void> resetPassword(String email) async {
    await _handleAuthAction(() async {
      await _authService.resetPassword(email.trim());
    });
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

  Future<void> _handleLogout() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _user = null;
    _lastActivityTime = null;
    await _storageService.clearToken();
    await _storageService.clearRefreshToken();
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
