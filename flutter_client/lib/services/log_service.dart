// lib/services/log_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/models/log_filter.dart';
import 'package:flutter_client/services/api_service.dart';

class LogService {
  final ApiService _apiService;

  LogService({required ApiService apiService}) : _apiService = apiService;

  Future<List<LogEntry>> getLogs(LogFilter filter) async {
    try {
      final response = await _apiService.request(
        path: '/api/v1/logs',
        method: 'GET',
        queryParameters: {
          if (filter.levels != null)
            'levels': filter.levels!.map((l) => l.name).toList(),
          if (filter.from != null) 'from': filter.from!.toIso8601String(),
          if (filter.to != null) 'to': filter.to!.toIso8601String(),
          if (filter.serverId != null) 'server_id': filter.serverId,
          if (filter.component != null) 'component': filter.component,
          if (filter.search != null) 'search': filter.search,
          'limit': filter.limit,
          'offset': filter.offset,
        },
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => LogEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response?.data != null) {
      final message = e.response?.data['message'] ?? '알 수 없는 오류가 발생했습니다.';
      return Exception(message);
    }
    return Exception('로그 서비스 오류: ${e.message}');
  }
}
