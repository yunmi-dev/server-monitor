// lib/services/monitoring_service.dart
import 'dart:async';
import 'package:flutter_client/models/chart_data.dart' as chart;
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/services/websocket_service.dart';
import 'package:flutter_client/models/socket_message.dart';

enum MetricType {
  distribution,
  load,
  memory,
  disk,
  network,
  error;

  String get topic => 'metrics.$name';
  MessageType get messageType {
    switch (this) {
      case MetricType.distribution:
        return MessageType.resourceMetrics;
      case MetricType.load:
        return MessageType.resourceMetrics;
      case MetricType.memory:
        return MessageType.resourceMetrics;
      case MetricType.disk:
        return MessageType.resourceMetrics;
      case MetricType.network:
        return MessageType.resourceMetrics;
      case MetricType.error:
        return MessageType.error;
    }
  }
}

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;

  late final ApiService _apiService;
  Timer? _heartbeatTimer;
  final _controllerMap =
      <MetricType, StreamController<List<chart.DistributionData>>>{};

  MonitoringService._internal() {
    _apiService = ApiService(
      baseUrl: AppConstants.baseUrl,
    );
    _setupHeartbeat();
  }

  void _setupHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    WebSocketService.instance.sendMessage(
      'ping',
      {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Distribution 데이터 스트림 구독
  Stream<List<chart.DistributionData>> getDistributionStream() {
    _controllerMap[MetricType.distribution] ??=
        StreamController<List<chart.DistributionData>>.broadcast();

    WebSocketService.instance.messageStream
        .where((message) => message.type == MetricType.distribution.messageType)
        .listen(
          (message) => _controllerMap[MetricType.distribution]?.add(
            (message.data['metrics'] as List)
                .map((item) => chart.DistributionData.fromJson(
                    item as Map<String, dynamic>))
                .toList(),
          ),
          onError: (error) =>
              _controllerMap[MetricType.distribution]?.addError(error),
        );

    return _controllerMap[MetricType.distribution]!.stream;
  }

  /// 최신 Distribution 데이터 가져오기
  Future<List<chart.DistributionData>> getDistributionData() async {
    try {
      final response = await _apiService.request(
        path: '/metrics/distribution',
        method: 'GET',
        queryParameters: {
          'duration': '1h',
          'interval': '5m',
        },
      );

      return (response.data.data as List)
          .map((item) =>
              chart.DistributionData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch distribution data: $e');
    }
  }

  /// 특정 기간의 메트릭 데이터 가져오기
  Future<List<chart.DistributionData>> getMetricsHistory({
    required DateTime start,
    required DateTime end,
    required String interval,
  }) async {
    try {
      final response = await _apiService.request(
        path: '/metrics/history',
        method: 'GET',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
          'interval': interval,
        },
      );

      return (response.data.data as List)
          .map((item) =>
              chart.DistributionData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch metrics history: $e');
    }
  }

  /// 리소스 사용량 통계 가져오기
  Future<Map<String, double>> getResourceStats() async {
    try {
      final response = await _apiService.request(
        path: '/metrics/stats',
        method: 'GET',
      );

      return Map<String, double>.from(response.data.data as Map);
    } catch (e) {
      throw Exception('Failed to fetch resource stats: $e');
    }
  }

  /// 서버별 성능 메트릭 가져오기
  Future<List<chart.DistributionData>> getServerMetrics(String serverId) async {
    try {
      final response = await _apiService.request(
        path: '/metrics/servers/$serverId',
        method: 'GET',
      );

      return (response.data.data as List)
          .map((item) =>
              chart.DistributionData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch server metrics: $e');
    }
  }

  /// 리소스 메트릭 가져오기
  Future<List<chart.ResourceMetrics>> getResourceMetrics() async {
    try {
      final response = await _apiService.request(
        path: '/metrics/resources',
        method: 'GET',
      );

      return (response.data.data as List)
          .map((item) =>
              chart.ResourceMetrics.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch resource metrics: $e');
    }
  }

  /// 리소스 메트릭 스트림 구독
  Stream<chart.ResourceMetrics> streamResourceMetrics(String serverId) {
    return _apiService
        .streamServerMetrics(serverId)
        .map((usage) => chart.ResourceMetrics(
              serverName: serverId,
              cpuUsage: usage.cpu,
              memoryUsage: usage.memory,
              diskUsage: usage.disk,
              status: usage.hasWarning ? 'warning' : 'normal',
              timestamp: usage.lastUpdated ?? DateTime.now(),
            ));
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    for (final controller in _controllerMap.values) {
      controller.close();
    }
    _controllerMap.clear();
  }
}
