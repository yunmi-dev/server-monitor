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

  Future<User> signInWithGoogle() async {
    return handleAuthRequest(() async {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final response = await _apiService.request(
        path: '/auth/google',
        method: 'POST',
        data: {
          'token': googleAuth.idToken ?? '',
          'name': googleUser.displayName ?? '',
          'email': googleUser.email,
          'photo': googleUser.photoUrl ?? '',
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signInWithApple() async {
    return handleAuthRequest(() async {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await _apiService.request(
        path: '/auth/apple',
        method: 'POST',
        data: {
          'token': credential.identityToken ?? '',
          'name': [
            credential.givenName,
            credential.familyName,
          ].where((e) => e != null).join(' '),
          'email': credential.email ?? '',
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signInWithKakao() async {
    return handleAuthRequest(() async {
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

      // 카카오 사용자 정보 가져오기
      final user = await kakao.UserApi.instance.me();

      final response = await _apiService.request(
        path: '/auth/kakao',
        method: 'POST',
        data: {
          'token': token!.accessToken,
          'name': user.kakaoAccount?.profile?.nickname ?? '',
          'email': user.kakaoAccount?.email ?? '',
          'photo': user.kakaoAccount?.profile?.profileImageUrl ?? '',
        },
      );

      final authResult = AuthResult.fromJson(response.data);
      await _handleAuthResult(authResult);
      return authResult.user;
    });
  }

  Future<User> signInWithFacebook() async {
    return handleAuthRequest(() async {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.accessToken == null) {
        throw AuthException('Failed to get Facebook access token');
      }

      // accessToken을 문자열로 변환
      final userData = await FacebookAuth.instance.getUserData();

      final response = await _apiService.request(
        path: '/auth/facebook',
        method: 'POST',
        data: {
          'token': result.accessToken!.toString(),
          'name': userData['name'],
          'email': userData['email'],
          'photo': userData['picture']?['data']?['url'],
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
  Future<User> refreshToken() async {
    return handleAuthRequest(() async {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        throw AuthException('No refresh token found');
      }

      // refresh token도 유효성 검사
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
      if (token == null) throw AuthException('No token found');

      // 토큰 유효성 검사 추가
      if (!_isTokenValid(token)) {
        // 토큰이 만료되었거나 곧 만료될 예정이면 갱신 시도
        try {
          return await refreshToken();
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

  Future<void> deleteAccount() async {
    return handleAuthRequest(() async {
      await _apiService.request(path: '/auth/account', method: 'DELETE');
      await _clearAuth();
    });
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

  void _setupTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5), // 5분마다 체크
      (_) async {
        try {
          final token = await _storageService.getToken();
          if (token == null) return;

          // 토큰이 유효하지 않거나 곧 만료될 예정이면 갱신
          if (!_isTokenValid(token)) {
            await refreshToken();
          }
        } catch (e) {
          logger.error('Automatic token refresh failed: $e');
        }
      },
    );
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
