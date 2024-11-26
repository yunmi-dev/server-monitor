// lib/utils/dio_error_handler.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_client/models/api_response.dart';

class DioErrorHandler {
  static DioException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error: ApiException(
            message:
                'Connection timeout. Please check your internet connection.',
            code: 'TIMEOUT_ERROR',
          ),
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return DioException(
          requestOptions: error.requestOptions,
          error: ApiException(
            message: 'Request cancelled',
            code: 'REQUEST_CANCELLED',
          ),
        );

      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: error.requestOptions,
          error: ApiException(
            message:
                'Connection failed. Please check your internet connection.',
            code: 'CONNECTION_ERROR',
          ),
        );

      default:
        if (error.error is SocketException) {
          return DioException(
            requestOptions: error.requestOptions,
            error: ApiException(
              message: 'Network error occurred. Please check your connection.',
              code: 'NETWORK_ERROR',
            ),
          );
        }
        return DioException(
          requestOptions: error.requestOptions,
          error: ApiException(
            message: 'An unexpected error occurred',
            code: 'UNKNOWN_ERROR',
          ),
        );
    }
  }

  static DioException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // API 응답이 우리 포맷인 경우
    if (responseData is Map<String, dynamic>) {
      try {
        final apiResponse = ApiResponse.fromJson(responseData);
        return DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          error: ApiException.fromResponse(apiResponse),
        );
      } catch (_) {
        // API 응답 파싱 실패
      }
    }

    // 기본 HTTP 상태 코드 기반 에러 처리
    String message;
    String code;

    switch (statusCode) {
      case 400:
        message = 'Bad request';
        code = 'BAD_REQUEST';
        break;
      case 401:
        message = 'Unauthorized';
        code = 'UNAUTHORIZED';
        break;
      case 403:
        message = 'Forbidden';
        code = 'FORBIDDEN';
        break;
      case 404:
        message = 'Not found';
        code = 'NOT_FOUND';
        break;
      case 405:
        message = 'Method not allowed';
        code = 'METHOD_NOT_ALLOWED';
        break;
      case 408:
        message = 'Request timeout';
        code = 'REQUEST_TIMEOUT';
        break;
      case 409:
        message = 'Conflict';
        code = 'CONFLICT';
        break;
      case 422:
        message = 'Validation error';
        code = 'VALIDATION_ERROR';
        break;
      case 500:
        message = 'Server error';
        code = 'SERVER_ERROR';
        break;
      case 502:
        message = 'Bad gateway';
        code = 'BAD_GATEWAY';
        break;
      case 503:
        message = 'Service unavailable';
        code = 'SERVICE_UNAVAILABLE';
        break;
      case 504:
        message = 'Gateway timeout';
        code = 'GATEWAY_TIMEOUT';
        break;
      default:
        message = 'An error occurred';
        code = 'UNKNOWN_ERROR';
    }

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      error: ApiException(
        message: message,
        code: code,
      ),
    );
  }
}
