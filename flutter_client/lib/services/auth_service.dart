// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_client/models/user.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'package:flutter_client/utils/logger.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_client/config/constants.dart';

part 'auth_service.freezed.dart';
part 'auth_service.g.dart';

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) = _AuthResult;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}

enum AuthProvider { email, google, apple, kakao, facebook }

class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AuthException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' ($code)' : ''}';
}

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  final GoogleSignIn _googleSignIn;
  Timer? _refreshTimer;
  User? _currentUser;
  bool _loading = false;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
    GoogleSignIn? googleSignIn,
  })  : _apiService = apiService,
        _storageService = storageService,
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;
  bool get isLoading => _loading;

  @protected
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @protected
  Future<T> handleAuthRequest<T>(Future<T> Function() request) async {
    try {
      setLoading(true);
      final result = await request();
      return result;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Authentication failed';
      final code = e.response?.data?['code'];
      throw AuthException(message, code: code, details: e);
    } on PlatformException catch (e) {
      throw AuthException(e.message ?? 'Platform error occurred',
          code: e.code, details: e.details);
    } catch (e) {
      throw AuthException(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<User> signInWithEmail(String email, String password) async {
    return handleAuthRequest(() async {
      // 개발 환경에서만 더미 인증 사용
      if (kDebugMode) {
        if (AppConstants.dummyAccounts.containsKey(email) &&
            AppConstants.dummyAccounts[email] == password) {
          // 더미 유저 데이터 생성
          final dummyUser = User(
            id: '1',
            email: email,
            name: email.split('@')[0],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // 더미 토큰 생성
          final dummyAuthResult = AuthResult(
            accessToken: 'dummy_access_token',
            refreshToken: 'dummy_refresh_token',
            user: dummyUser,
          );

          await _handleAuthResult(dummyAuthResult);
          return dummyUser;
        }
      }

      // 프로덕션 환경에서는 실제 API 호출
      final response = await _apiService.request(
        path: '/auth/login',
        method: 'POST',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signInWithApple() async {
    return handleAuthRequest(() async {
      if (kDebugMode) {
        // 더미 유저 데이터 생성
        final dummyUser = User(
          id: 'apple_mock_id',
          email: 'apple_user@example.com',
          name: 'Apple User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final dummyAuthResult = AuthResult(
          accessToken: 'dummy_apple_access_token',
          refreshToken: 'dummy_apple_refresh_token',
          user: dummyUser,
        );

        await _handleAuthResult(dummyAuthResult);
        return dummyUser;
      }
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await _apiService.request(
        path: '/auth/social-login',
        method: 'POST',
        data: {
          'provider': 'apple',
          'token': credential.identityToken ?? '',
          'email': credential.email,
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signInWithKakao() async {
    return handleAuthRequest(() async {
      if (kDebugMode) {
        // 더미 유저 데이터로 즉시 반환
        final dummyUser = User(
          id: 'kakao_${DateTime.now().millisecondsSinceEpoch}',
          email: 'kakao_test@example.com',
          name: '카카오 테스트',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final dummyAuthResult = AuthResult(
          accessToken: 'dummy_kakao_access_token',
          refreshToken: 'dummy_kakao_refresh_token',
          user: dummyUser,
        );

        await _handleAuthResult(dummyAuthResult);
        return dummyUser;
      }

      // 프로덕션 코드는 그대로 유지
      if (await kakao.isKakaoTalkInstalled()) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final token =
          await kakao.TokenManagerProvider.instance.manager.getToken();
      if (token?.accessToken == null) {
        throw AuthException('Failed to get Kakao access token');
      }

      final response = await _apiService.request(
        path: '/auth/social-login',
        method: 'POST',
        data: {
          'provider': 'kakao',
          'token': token!.accessToken,
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signInWithFacebook() async {
    return handleAuthRequest(() async {
      if (kDebugMode) {
        // 더미 유저 데이터로 즉시 반환
        final dummyUser = User(
          id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
          email: 'facebook_test@example.com',
          name: 'Facebook 테스트',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final dummyAuthResult = AuthResult(
          accessToken: 'dummy_facebook_access_token',
          refreshToken: 'dummy_facebook_refresh_token',
          user: dummyUser,
        );

        await _handleAuthResult(dummyAuthResult);
        return dummyUser;
      }

      // 프로덕션 코드는 그대로 유지
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.accessToken == null) {
        throw AuthException('Failed to get Facebook access token');
      }

      final response = await _apiService.request(
        path: '/auth/social-login',
        method: 'POST',
        data: {
          'provider': 'facebook',
          'token': result.accessToken!.toString(),
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signInWithGoogle() async {
    return handleAuthRequest(() async {
      if (kDebugMode) {
        // 더미 유저 데이터로 즉시 반환
        final dummyUser = User(
          id: 'google_${DateTime.now().millisecondsSinceEpoch}',
          email: 'google_test@example.com',
          name: 'Google 테스트',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final dummyAuthResult = AuthResult(
          accessToken: 'dummy_google_access_token',
          refreshToken: 'dummy_google_refresh_token',
          user: dummyUser,
        );

        await _handleAuthResult(dummyAuthResult);
        return dummyUser;
      }

      // 프로덕션 코드는 그대로 유지
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;

      final response = await _apiService.request(
        path: '/auth/social-login',
        method: 'POST',
        data: {
          'provider': 'google',
          'token': googleAuth.idToken,
          'email': googleUser.email,
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return handleAuthRequest(() async {
      // 개발 환경인 경우 더미 응답 사용
      if (kDebugMode) {
        // 더미 유저 데이터 생성
        final dummyUser = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 더미 인증 결과 생성
        final dummyAuthResult = AuthResult(
          accessToken: 'dummy_access_token_${dummyUser.id}',
          refreshToken: 'dummy_refresh_token_${dummyUser.id}',
          user: dummyUser,
        );

        await _handleAuthResult(dummyAuthResult);
        return dummyUser;
      }

      // 프로덕션 환경에서는 실제 API 호출
      final response = await _apiService.request(
        path: '/auth/register',
        method: 'POST',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<void> signOut() async {
    return handleAuthRequest(() async {
      await _apiService.request(path: '/auth/logout', method: 'POST');
      await _clearAuth();

      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await FacebookAuth.instance.logOut();
      try {
        await kakao.UserApi.instance.logout();
      } catch (_) {}
    });
  }

  Future<User> updateProfile({
    String? name,
    String? email,
    Uint8List? profileImage,
  }) async {
    return handleAuthRequest(() async {
      final formData = <String, String>{};

      if (name != null) formData['name'] = name;
      if (email != null) formData['email'] = email;
      if (profileImage != null) {
        // Handle profile image upload separately if needed
      }

      final response = await _apiService.request(
        path: '/auth/profile',
        method: 'PUT',
        data: formData,
      );

      final updatedUser = User.fromJson(response.data['user']);
      _currentUser = updatedUser;
      notifyListeners();
      return updatedUser;
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return handleAuthRequest(() async {
      await _apiService.request(
        path: '/auth/password',
        method: 'PUT',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    });
  }

  // 토큰 갱신 전에 refreshToken 유효성 검사 추가
  Future<User> refreshToken(String refreshToken) async {
    return handleAuthRequest(() async {
      if (refreshToken.isEmpty) {
        throw AuthException('No refresh token provided');
      }

      // refresh token 유효성 검사
      if (!_isTokenValid(refreshToken)) {
        await _clearAuth();
        throw AuthException('Refresh token expired. Please sign in again.');
      }

      final response = await _apiService.request(
        path: '/auth/refresh',
        method: 'POST',
        data: {'refresh_token': refreshToken},
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> getCurrentUser() async {
    return handleAuthRequest(() async {
      if (_currentUser != null) return _currentUser!;

      final token = await _storageService.getToken();
      final refreshTokenStr = await _storageService.getRefreshToken();

      if (token == null || refreshTokenStr == null) {
        throw AuthException('No token found');
      }

      // 토큰 유효성 검사 추가
      if (!_isTokenValid(token)) {
        // 토큰이 만료되었거나 곧 만료될 예정이면 갱신 시도
        try {
          // refreshToken 메서드 호출 시 문자열로 전달
          return await refreshToken(refreshTokenStr);
        } catch (e) {
          await _clearAuth();
          throw AuthException('Session expired. Please sign in again.');
        }
      }

      final response = await _apiService.request(
        path: '/auth/me',
        method: 'GET',
      );

      _currentUser = User.fromJson(response.data['user']);
      notifyListeners();
      return _currentUser!;
    });
  }

  void _setupTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        try {
          final token = await _storageService.getToken();
          final refreshTokenStr = await _storageService.getRefreshToken();

          if (token == null || refreshTokenStr == null) return;

          if (!_isTokenValid(token)) {
            // refreshToken 메서드 호출 시 문자열로 전달
            await refreshToken(refreshTokenStr);
          }
        } catch (e) {
          logger.error('Automatic token refresh failed: $e');
        }
      },
    );
  }

  Future<void> deleteAccount({String? password}) async {
    try {
      _loading = true;
      notifyListeners();

      await _apiService.request(
        path: '/auth/account',
        method: 'DELETE',
        data: password != null ? {'password': password} : null,
      );

      // 소셜 로그인 연동 해제
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await FacebookAuth.instance.logOut();
      try {
        await kakao.UserApi.instance.logout();
      } catch (_) {}

      await _clearAuth();
    } catch (e) {
      logger.error('Failed to delete account: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    return handleAuthRequest(() async {
      await _apiService.request(
        path: '/auth/reset-password',
        method: 'POST',
        data: {
          'email': email,
        },
      );
    });
  }

  Future<void> _handleAuthResult(AuthResult result) async {
    await _storageService.setToken(result.accessToken);
    await _storageService.setRefreshToken(result.refreshToken);
    _currentUser = result.user;
    _setupTokenRefresh();
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _currentUser = null;
    await _storageService.clearToken();
    await _storageService.clearRefreshToken();
    notifyListeners();
  }

  bool _isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      // 토큰 만료 5분 전부터는 갱신이 필요하다고 판단
      return DateTime.now()
          .isBefore(expiry.subtract(const Duration(minutes: 5)));
    } catch (e) {
      logger.error('Token validation failed: $e');
      return false;
    }
  }

  // 토큰 페이로드 파싱 유틸리티 메서드 추가
  Map<String, dynamic>? getTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      return json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
    } catch (e) {
      logger.error('Token payload parsing failed: $e');
      return null;
    }
  }

  // 토큰에서 사용자 ID 추출 유틸리티 메서드 추가
  String? getUserIdFromToken(String token) {
    final payload = getTokenPayload(token);
    return payload?['sub'] as String?;
  }

  // 토큰 만료 시간 확인 유틸리티 메서드 추가
  Duration? getTokenTimeRemaining(String token) {
    try {
      final payload = getTokenPayload(token);
      if (payload == null) return null;

      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return expiry.difference(DateTime.now());
    } catch (e) {
      logger.error('Token expiry check failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _googleSignIn.disconnect();
    super.dispose();
  }
}
