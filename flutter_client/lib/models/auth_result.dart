// lib/models/auth_result.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_client/models/user.dart';

part 'auth_result.freezed.dart';
part 'auth_result.g.dart';

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) = _AuthResult;

  factory AuthResult.fromJson(Map<String, dynamic> json) => _AuthResult(
        accessToken: json['token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
