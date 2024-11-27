// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_client/models/api_response.dart';
import 'package:flutter_client/utils/dio_error_handler.dart';
import 'package:flutter_client/services/websocket_service.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/models/resource_usage.dart';
import 'package:flutter_client/models/alert.dart';
import 'package:flutter_client/models/socket_message.dart';
// import 'package:flutter_client/models/alert_rule.dart';
// import 'package:flutter_client/models/alert_status.dart';
import 'package:flutter_client/models/log_entry.dart';

class ApiService {
  late final Dio _dio;
  final WebSocketService _webSocketService;

  ApiService({
    required String baseUrl,
    Dio? dio,
    WebSocketService? webSocketService,
  }) : _webSocketService = webSocketService ?? WebSocketService.instance {
    _dio = dio ?? _createDio(baseUrl);
    _setupInterceptors();
  }

  Dio _createDio(String baseUrl) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    ));
  }

  void _setupInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          debugPrint(obj.toString());
        },
      ));
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          if (response.data != null) {
            response.data = ApiResponse.fromJson(response.data);
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          return handler.next(DioErrorHandler.handle(error));
        },
      ),
    );
  }

  Future<T> _handleRequest<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) converter,
  ) async {
    try {
      final response = await request();
      final apiResponse = response.data as ApiResponse;

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message ?? 'Request failed',
          code: apiResponse.code,
        );
      }

      return converter(apiResponse.data);
    } on DioException catch (e) {
      throw DioErrorHandler.handle(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // 서버 추가
  Future<Server> addServer({
    required String name,
    required String host,
    required int port,
    required String username,
    required String password,
    required String type,
  }) async {
    return _handleRequest<Server>(
      () => _dio.post(
        '/servers',
        data: {
          'name': name,
          'host': host,
          'port': port,
          'username': username,
          'password': password,
          'type': type,
        },
      ),
      (data) => Server.fromJson(data as Map<String, dynamic>),
    );
  }

  // 서버 업데이트
  Future<Server> updateServer(Server server) async {
    return _handleRequest<Server>(
      () => _dio.put(
        '/servers/${server.id}',
        data: server.toJson(),
      ),
      (data) => Server.fromJson(data as Map<String, dynamic>),
    );
  }

  // 서버 삭제
  Future<void> deleteServer(String serverId) async {
    await _handleRequest<void>(
      () => _dio.delete('/servers/$serverId'),
      (_) {},
    );
  }

  // 서버 시작
  Future<void> restartServer(String serverId) async {
    return _handleRequest<void>(
      () => _dio.post('/servers/$serverId/restart'),
      (_) {},
    );
  }

  // 서버 상태 조회
  Future<ServerStatus> getServerStatus(String serverId) async {
    return _handleRequest<ServerStatus>(
      () => _dio.get('/servers/$serverId/status'),
      (data) {
        final statusStr = (data as Map<String, dynamic>)['status'] as String;
        return ServerStatus.fromString(statusStr);
      },
    );
  }

  // 서버 연결 테스트
  Future<void> testServerConnection({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    await _handleRequest<void>(
      () => _dio.post(
        '/servers/test-connection',
        data: {
          'host': host,
          'port': port,
          'username': username,
          'password': password,
        },
      ),
      (_) {},
    );
  }

  /// 서버 상태에 대한 트렌드 데이터 조회
  Future<Map<String, List<int>>> getServerTrends({
    int days = 5,
    String? type,
  }) async {
    return _handleRequest<Map<String, List<int>>>(
      () => _dio.get(
        '/servers/trends',
        queryParameters: {
          'days': days.toString(),
          if (type != null) 'type': type,
        },
      ),
      (data) => {
        'total': List<int>.from(data['total'] ?? []),
        'at_risk': List<int>.from(data['at_risk'] ?? []),
        'safe': List<int>.from(data['safe'] ?? []),
      },
    );
  }

  /// 특정 서버의 리소스 사용량 트렌드 조회
  Future<Map<String, List<double>>> getServerResourceTrends({
    required String serverId,
    Duration duration = const Duration(hours: 24),
    String? resourceType, // 'cpu', 'memory', 'disk', 'network'
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(duration);

    return _handleRequest<Map<String, List<double>>>(
      () => _dio.get(
        '/servers/$serverId/resource-trends',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          if (resourceType != null) 'type': resourceType,
        },
      ),
      (data) => Map<String, List<double>>.from(
        data.map((key, value) => MapEntry(
              key as String,
              (value as List).map((v) => (v as num).toDouble()).toList(),
            )),
      ),
    );
  }

  // Alert 관련 API 메서드들
  Future<List<Alert>> getAlerts({
    Map<String, dynamic>? filters,
  }) async {
    return _handleRequest<List<Alert>>(
      () => _dio.get(
        '/alerts',
        queryParameters: filters,
      ),
      (data) => (data as List)
          .map((json) => Alert.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> deleteAlert(String id) async {
    await _handleRequest<void>(
      () => _dio.delete('/alerts/$id'),
      (_) {},
    );
  }

  Future<void> markAlertsAsRead(List<String> ids) async {
    await _handleRequest<void>(
      () => _dio.patch(
        '/alerts/batch/read',
        data: {'ids': ids},
      ),
      (_) {},
    );
  }

  Future<void> acknowledgeAlert(String id, String userId) async {
    await _handleRequest<void>(
      () => _dio.patch(
        '/alerts/$id/acknowledge',
        data: {'userId': userId},
      ),
      (_) {},
    );
  }

  Future<void> resolveAlert(String id, String userId) async {
    await _handleRequest<void>(
      () => _dio.patch(
        '/alerts/$id/resolve',
        data: {'userId': userId},
      ),
      (_) {},
    );
  }

  Stream<Alert> streamAlerts(String serverId) {
    return _webSocketService.messageStream
        .where((message) =>
            message.type == MessageType.alert &&
            message.data['serverId'] == serverId)
        .map((message) => Alert.fromJson(message.data));
  }

  // Alert 필터 관련 메서드 추가
  Future<Map<String, int>> getAlertStats() async {
    return _handleRequest<Map<String, int>>(
      () => _dio.get('/alerts/stats'),
      (data) => Map<String, int>.from(data as Map),
    );
  }

  Future<List<String>> getAlertCategories() async {
    return _handleRequest<List<String>>(
      () => _dio.get('/alerts/categories'),
      (data) => List<String>.from(data as List),
    );
  }

  // 배치 작업을 위한 메서드
  Future<void> batchUpdateAlerts({
    required List<String> ids,
    required Map<String, dynamic> updates,
  }) async {
    await _handleRequest<void>(
      () => _dio.patch(
        '/alerts/batch',
        data: {
          'ids': ids,
          'updates': updates,
        },
      ),
      (_) {},
    );
  }

  // Alert 룰 관련 메서드
  Future<void> createAlertRule(Map<String, dynamic> rule) async {
    await _handleRequest<void>(
      () => _dio.post(
        '/alerts/rules',
        data: rule,
      ),
      (_) {},
    );
  }

  Future<List<Map<String, dynamic>>> getAlertRules() async {
    return _handleRequest<List<Map<String, dynamic>>>(
      () => _dio.get('/alerts/rules'),
      (data) => List<Map<String, dynamic>>.from(data as List),
    );
  }

  Future<List<Server>> getServers() async {
    return _handleRequest<List<Server>>(
      () => _dio.get('/servers'),
      (data) => (data as List)
          .map((json) => Server.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Server> getServerDetails(String serverId) async {
    return _handleRequest<Server>(
      () => _dio.get('/servers/$serverId'),
      (data) => Server.fromJson(data as Map<String, dynamic>),
    );
  }

  Stream<ResourceUsage> streamServerMetrics(String serverId) {
    return _webSocketService.messageStream
        .where(
            (message) => message.type.toString() == 'server_metrics_$serverId')
        .map((message) => ResourceUsage.fromJson(message.data));
  }

  Future<Response<T>> request<T>({
    required String path,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: options?.headers,
          contentType: options?.contentType,
          responseType: options?.responseType,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw DioErrorHandler.handle(e);
    }
  }

  Future<Response<T>> uploadFile<T>({
    required String path,
    required List<int> bytes,
    required String filename,
    Map<String, dynamic>? extraData,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData();

    formData.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    ));

    if (extraData != null) {
      formData.fields.addAll(
        extraData.entries.map(
          (e) => MapEntry(e.key, e.value.toString()),
        ),
      );
    }

    return request<T>(
      path: path,
      method: 'POST',
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Map<String, dynamic>> getLogs({
    String? serverId,
    List<String>? levels,
    String? startDate,
    String? endDate,
    String? search,
    int? limit,
    String? before,
  }) async {
    return _handleRequest<Map<String, dynamic>>(
      () => _dio.get(
        '/logs',
        queryParameters: {
          if (serverId != null) 'serverId': serverId,
          if (levels != null && levels.isNotEmpty) 'levels': levels.join(','),
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (search != null && search.isNotEmpty) 'search': search,
          if (limit != null) 'limit': limit.toString(),
          if (before != null) 'before': before,
        },
      ),
      (data) => data as Map<String, dynamic>,
    );
  }

  // 전체 로그 조회 메서드 (내보내기용)
  Future<Map<String, dynamic>> getAllLogs({
    String? serverId,
    List<String>? levels,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    return _handleRequest<Map<String, dynamic>>(
      () => _dio.get(
        '/logs/export',
        queryParameters: {
          if (serverId != null) 'serverId': serverId,
          if (levels != null && levels.isNotEmpty) 'levels': levels.join(','),
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (search != null && search.isNotEmpty) 'search': search,
          'all': 'true',
        },
      ),
      (data) => data as Map<String, dynamic>,
    );
  }

  // 실시간 로그 스트림
  Stream<LogEntry> streamLogs(String? serverId) {
    return _webSocketService.messageStream
        .where((message) =>
            message.type == MessageType.log &&
            (serverId == null || message.data['serverId'] == serverId))
        .map((message) => LogEntry.fromJson(message.data));
  }

  // 로그 삭제
  Future<void> deleteLogs({
    String? serverId,
    List<String>? levels,
    DateTime? before,
  }) async {
    await _handleRequest<void>(
      () => _dio.delete(
        '/logs',
        queryParameters: {
          if (serverId != null) 'serverId': serverId,
          if (levels != null && levels.isNotEmpty) 'levels': levels.join(','),
          if (before != null) 'before': before.toIso8601String(),
        },
      ),
      (_) {},
    );
  }

  // 특정 기간의 로그 통계 조회
  Future<Map<String, dynamic>> getLogStats({
    String? serverId,
    List<String>? levels,
    String? startDate,
    String? endDate,
  }) async {
    return _handleRequest<Map<String, dynamic>>(
      () => _dio.get(
        '/logs/stats',
        queryParameters: {
          if (serverId != null) 'serverId': serverId,
          if (levels != null && levels.isNotEmpty) 'levels': levels.join(','),
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      ),
      (data) => data as Map<String, dynamic>,
    );
  }
}
