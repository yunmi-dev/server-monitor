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
    @JsonKey(name: 'role') required String role, // 추가
    @JsonKey(name: 'provider') required String provider, // 추가
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    String? profileUrl,
    @Default(false) bool isEmailVerified,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    Map<String, dynamic>? preferences,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson({
        ...json,
        'created_at': json['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': json['updated_at'] ?? DateTime.now().toIso8601String(),
      });
}
