// lib/models/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @JsonKey(name: 'role') required String role,
    @JsonKey(name: 'provider') required String provider,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    String? profileUrl,
    @Default(false) bool isEmailVerified,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
    @JsonKey(name: 'created_at') DateTime? createdAt, // required 제거
    @JsonKey(name: 'updated_at') DateTime? updatedAt, // required 제거
    Map<String, dynamic>? preferences,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json); // 기본값 로직 제거
}
