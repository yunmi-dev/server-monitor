// lib/models/api_response.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@freezed
class ApiResponse with _$ApiResponse {
  const factory ApiResponse({
    required bool success,
    @JsonKey(includeIfNull: false) String? message,
    @JsonKey(includeIfNull: false) String? code,
    @JsonKey(includeIfNull: false) dynamic data,
    @Default({}) Map<String, dynamic> meta,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);

  /// 성공 응답 생성
  factory ApiResponse.success({
    dynamic data,
    String? message,
    Map<String, dynamic>? meta,
  }) =>
      ApiResponse(
        success: true,
        data: data,
        message: message,
        meta: meta ?? const {},
      );

  /// 에러 응답 생성
  factory ApiResponse.error({
    required String message,
    String? code,
    Map<String, dynamic>? meta,
  }) =>
      ApiResponse(
        success: false,
        message: message,
        code: code,
        meta: meta ?? const {},
      );

  /// Pagination 메타데이터 포함된 응답 생성
  factory ApiResponse.paginated({
    required List<dynamic> data,
    required int total,
    required int page,
    required int perPage,
  }) =>
      ApiResponse(
        success: true,
        data: data,
        meta: {
          'pagination': {
            'total': total,
            'page': page,
            'per_page': perPage,
            'total_pages': (total / perPage).ceil(),
          }
        },
      );
}

/// API 예외 처리를 위한 커스텀 Exception
class ApiException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? meta;

  ApiException({
    required this.message,
    this.code,
    this.meta,
  });

  @override
  String toString() =>
      'ApiException: $message${code != null ? ' ($code)' : ''}';

  factory ApiException.fromResponse(ApiResponse response) {
    return ApiException(
      message: response.message ?? 'Unknown error occurred',
      code: response.code,
      meta: response.meta,
    );
  }
}

// TODO: ApiException 인증이 필요