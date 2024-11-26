// lib/utils/validation_utils.dart
import 'package:flutter_client/config/constants.dart';

class ValidationUtils {
  static final _emailRegex = RegExp(AppConstants.emailRegex);
  static final _passwordRegex = RegExp(AppConstants.passwordRegex);
  static final _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );
  static final _ipRegex = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );
  static final _portRegex = RegExp(
      r'^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$');

  // 이메일 검증
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!_emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  // 비밀번호 검증
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return '비밀번호는 ${AppConstants.minPasswordLength}자 이상이어야 합니다';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return '비밀번호는 영문, 숫자, 특수문자를 포함해야 합니다';
    }
    return null;
  }

  // 비밀번호 확인 검증
  static String? validateConfirmPassword(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return '비밀번호를 다시 입력해주세요';
    }
    if (password != confirmPassword) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  // 필수 입력 검증
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }
    return null;
  }

  // URL 검증
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL을 입력해주세요';
    }
    if (!_urlRegex.hasMatch(value)) {
      return '올바른 URL 형식이 아닙니다';
    }
    return null;
  }

  // IP 주소 검증
  static String? validateIpAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'IP 주소를 입력해주세요';
    }
    if (!_ipRegex.hasMatch(value)) {
      return '올바른 IP 주소 형식이 아닙니다';
    }
    return null;
  }

  // 포트 번호 검증
  static String? validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return '포트 번호를 입력해주세요';
    }
    if (!_portRegex.hasMatch(value)) {
      return '올바른 포트 번호가 아닙니다 (0-65535)';
    }
    return null;
  }

  // 숫자 범위 검증
  static String? validateNumberRange(
    String? value,
    double min,
    double max,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '올바른 숫자를 입력해주세요';
    }

    if (number < min || number > max) {
      return '$fieldName은(는) $min에서 $max 사이여야 합니다';
    }

    return null;
  }
}
