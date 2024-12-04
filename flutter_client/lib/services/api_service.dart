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
  static const String API_PREFIX = '/api/v1'; // 여기서 한번만 정의

  ApiService({
    required String baseUrl,
    Dio? dio,
    WebSocketService? webSocketService,
  }) : _webSocketService = webSocketService ?? WebSocketService.instance {
    _dio = dio ?? _createDio(baseUrl);
    _setupInterceptors();
  }

// ApiService class의 _handleRequest 메서드 내부 // Test
  Future<T> _handleRequest<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) converter,
  ) async {
    try {
      final response = await request();
      debugPrint('API Response: ${response.data}'); // 응답 데이터 로깅 추가

      if (response.data == null) {
        throw ApiException(message: 'Empty response from server');
      }

      final apiResponse = response.data is ApiResponse
          ? response.data as ApiResponse
          : ApiResponse.fromJson(response.data as Map<String, dynamic>);

      debugPrint('Parsed ApiResponse: ${apiResponse.data}'); // 파싱된 데이터 로깅 추가

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message ?? 'Request failed',
          code: apiResponse.code,
        );
      }

      return converter(apiResponse.data);
    } catch (e, stack) {
      debugPrint('Error in _handleRequest: $e'); // 에러 로깅 추가
      debugPrint('Stack trace: $stack'); // 스택 트레이스 로깅 추가
      rethrow;
    }
  }

  Dio _createDio(String baseUrl) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10), // 타임아웃 시간 증가
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      validateStatus: (status) {
        return status != null && status < 500;
      },
      headers: {
        'Accept': 'application/json',
      },
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
        onResponse: (response, handler) async {
          if (response.data != null) {
            // 응답이 비어있지 않고 Map 형태일 때만 ApiResponse로 변환
            if (response.data is Map<String, dynamic>) {
              try {
                response.data = ApiResponse.fromJson(response.data);
              } catch (e) {
                debugPrint('Error parsing API response: $e');
              }
            }
          }
          return handler.next(response);
        },
      ),
    );
  }

  // Future<T> _handleRequest<T>(
  //   Future<Response<dynamic>> Function() request,
  //   T Function(dynamic data) converter,
  // ) async {
  //   try {
  //     final response = await request();

  //     if (response.data == null) {
  //       throw ApiException(message: 'Empty response from server');
  //     }

  //     final apiResponse = response.data is ApiResponse
  //         ? response.data as ApiResponse
  //         : ApiResponse.fromJson(response.data as Map<String, dynamic>);

  //     if (!apiResponse.success) {
  //       throw ApiException(
  //         message: apiResponse.message ?? 'Request failed',
  //         code: apiResponse.code,
  //       );
  //     }

  //     return converter(apiResponse.data);
  //   } on DioException catch (e) {
  //     throw DioErrorHandler.handle(e);
  //   } catch (e) {
  //     throw ApiException(message: e.toString());
  //   }
  // }

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
        '$API_PREFIX/servers',
        data: {
          'name': name,
          'host': host,
          'port': port,
          'username': username,
          'password': password,
          'server_type': type,
        },
      ),
      (data) {
        // data가 Map이 아닌 경우 처리
        if (data is! Map<String, dynamic>) {
          throw ApiException(message: 'Invalid server data format');
        }
        return Server.fromJson(data);
      },
    );
  }

  Future<List<Server>> getServers() async {
    try {
      debugPrint('서버 목록 조회 시작');
      final response = await _dio.get('$API_PREFIX/servers');

      debugPrint('서버 응답: ${response.data}');
      final apiResponse = ApiResponse.fromJson(response.data);

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message ?? '서버 목록을 불러오는데 실패했습니다',
          code: apiResponse.code,
        );
      }

      final List<dynamic> serversData = apiResponse.data as List;
      return serversData.map((json) {
        debugPrint('서버 데이터 파싱: $json');
        return Server.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('서버 목록 조회 오류: $e');
      rethrow;
    }
  }

  Future<Server> getServerDetails(String serverId) async {
    try {
      final response = await _dio.get('/servers/$serverId');
      final apiResponse = response.data as ApiResponse;

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message ?? 'Failed to fetch server details',
          code: apiResponse.code,
        );
      }

      return Server.fromJson(apiResponse.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException(message: '서버 정보를 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  Stream<ResourceUsage> streamServerMetrics(String serverId) {
    return _webSocketService.messageStream
        .where((message) =>
            message.type == MessageType.resourceMetrics &&
            message.data['serverId'] == serverId)
        .map((message) => ResourceUsage.fromJson(message.data));
  }

  // 서버 `업데이트`
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
        '$API_PREFIX/servers/test-connection',
        data: {
          'host': host,
          'port': port,
          'username': username,
          'password': password,
        },
      ),
      (data) => data,
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
