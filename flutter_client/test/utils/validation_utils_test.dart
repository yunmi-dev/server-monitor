// test/utils/validation_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_client/utils/validation_utils.dart';
import 'package:flutter_client/config/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ValidationUtils - Email Validation', () {
    test('valid emails should pass validation', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.kr',
        'user+label@domain.com',
        'user123@subdomain.domain.org',
        'test.email@example.com',
      ];

      for (final email in validEmails) {
        final result = ValidationUtils.validateEmail(email);
        expect(result, isNull, reason: 'Email $email should be valid');
      }
    });

    test('invalid emails should return error message', () {
      final invalidEmails = [
        '', // 빈 이메일
        'test', // @ 없음
        '@domain.com', // 로컬 파트 없음
        'test@', // 도메인 없음
        'test@.', // 잘못된 도메인
        'test@.com', // 잘못된 도메인
        'test.@domain.com', // 잘못된 로컬 파트
        'test..test@domain.com', // 연속된 점
      ];

      for (final email in invalidEmails) {
        final result = ValidationUtils.validateEmail(email);
        expect(result, isNotNull, reason: 'Email $email should be invalid');
        expect(result, isA<String>());
      }
    });
  });

  group('ValidationUtils - Password Validation', () {
    test('valid passwords should pass validation', () {
      final validPasswords = [
        'Password123!',
        'Complex@Password789',
        'Secure123#Password',
        'Test123@abc',
      ];

      for (final password in validPasswords) {
        final result = ValidationUtils.validatePassword(password);
        expect(result, isNull, reason: 'Password $password should be valid');
      }
    });

    test('invalid passwords should return error message', () {
      final invalidPasswords = [
        '', // 빈 비밀번호
        'abc', // 너무 짧음
        'password', // 숫자, 특수문자 없음
        'Password', // 숫자, 특수문자 없음
        '12345678', // 문자, 특수문자 없음
        'Password123', // 특수문자 없음
        'Password!@#', // 숫자 없음
      ];

      for (final password in invalidPasswords) {
        final result = ValidationUtils.validatePassword(password);
        expect(result, isNotNull,
            reason: 'Password $password should be invalid');
        expect(result, isA<String>());
      }
    });

    test('password should meet minimum length requirement', () {
      final password = 'Pw1!'; // 최소 길이보다 짧은 비밀번호
      final result = ValidationUtils.validatePassword(password);
      expect(result, contains('${AppConstants.minPasswordLength}자 이상'));
    });
  });

  group('ValidationUtils - Server Name Validation', () {
    test('valid server names should pass validation', () {
      final validNames = [
        'Production Server',
        'Dev-Server-001',
        'Test Server 123',
        'Development',
      ];

      for (final name in validNames) {
        final result = ValidationUtils.validateServerName(name);
        expect(result, isNull, reason: 'Server name $name should be valid');
      }
    });

    test('invalid server names should return error message', () {
      final invalidNames = [
        '', // 빈 이름
        'ab', // 3자 미만
        'a' * 51, // 50자 초과
      ];

      for (final name in invalidNames) {
        final result = ValidationUtils.validateServerName(name);
        expect(result, isNotNull,
            reason: 'Server name $name should be invalid');
        expect(result, isA<String>());
      }
    });
  });

  group('ValidationUtils - Host Validation', () {
    test('valid hosts should pass validation', () {
      final validHosts = [
        '192.168.1.1',
        'example.com',
        'test.domain.co.kr',
        '10.0.0.1',
        '255.255.255.255',
      ];

      for (final host in validHosts) {
        final result = ValidationUtils.validateHost(host);
        expect(result, isNull, reason: 'Host $host should be valid');
      }
    });

    test('invalid hosts should return error message', () {
      final invalidHosts = [
        '', // 빈 호스트
        '256.256.256.256', // 잘못된 IP
        '192.168.1', // 불완전한 IP
        'invalid..com', // 잘못된 도메인
        '-test.com', // 하이픈으로 시작하는 도메인
        'test-.com', // 하이픈으로 끝나는 도메인
      ];

      for (final host in invalidHosts) {
        final result = ValidationUtils.validateHost(host);
        expect(result, isNotNull, reason: 'Host $host should be invalid');
        expect(result, isA<String>());
      }
    });
  });

  group('ValidationUtils - Port Validation', () {
    test('valid ports should pass validation', () {
      final validPorts = [
        '80',
        '443',
        '3000',
        '8080',
        '65535',
      ];

      for (final port in validPorts) {
        final result = ValidationUtils.validatePort(port);
        expect(result, isNull, reason: 'Port $port should be valid');
      }
    });

    test('invalid ports should return error message', () {
      final invalidPorts = [
        '', // 빈 포트
        '-1', // 음수
        '65536', // 범위 초과
        'abc', // 문자
        '1.5', // 소수
      ];

      for (final port in invalidPorts) {
        final result = ValidationUtils.validatePort(port);
        expect(result, isNotNull, reason: 'Port $port should be invalid');
        expect(result, isA<String>());
      }
    });
  });
}
