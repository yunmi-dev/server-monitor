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
    String? profileImage,
    @Default(false) bool isEmailVerified,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, dynamic>? preferences,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
