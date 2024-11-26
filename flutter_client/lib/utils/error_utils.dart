// lib/utils/error_utils.dart
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';

class ErrorUtils {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return '네트워크 연결을 확인해주세요';
    } else if (error is TimeoutException) {
      return '요청 시간이 초과되었습니다';
    } else if (error is FormatException) {
      return '데이터 형식이 올바르지 않습니다';
    } else {
      return error?.toString() ?? '알 수 없는 오류가 발생했습니다';
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버와의 연결이 지연되고 있습니다';

      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없습니다';

      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);

      case DioExceptionType.cancel:
        return '요청이 취소되었습니다';

      default:
        return '서버 오류가 발생했습니다';
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다';
      case 401:
        return '인증이 필요합니다';
      case 403:
        return '접근이 거부되었습니다';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다';
      case 409:
        return '리소스 충돌이 발생했습니다';
      case 429:
        return '너무 많은 요청이 발생했습니다';
      case 500:
        return '서버 내부 오류가 발생했습니다';
      case 502:
        return '서버가 응답하지 않습니다';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다';
      default:
        return '알 수 없는 오류가 발생했습니다';
    }
  }
}
