// lib/utils/logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  final Logger _logger;

  // kReleaseMode를 사용하여 프로덕션 환경에서는 로그 레벨을 높게 설정
  AppLogger()
      : _logger = Logger(
          filter: ProductionFilter(), // 프로덕션에서는 debug 로그를 제외
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            printTime: true,
          ),
          level: Level.info, // 기본 레벨을 INFO로 설정
        );

  // 리소스 메트릭 메시지와 같은 빈번한 로그는 verbose로 처리
  void verbose(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  // 개발 중 디버깅용 메시지
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  // 일반적인 정보성 메시지
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // 잠재적 문제나 주의가 필요한 상황
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // 실제 에러 상황
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // 심각한 에러나 예상치 못한 상황
  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error: error, stackTrace: stackTrace);
  }
}

// 싱글톤 인스턴스 생성
final logger = AppLogger();
