// lib/providers/server_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/utils/error_utils.dart';
import 'package:flutter_client/models/time_series_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_client/models/time_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client/services/websocket_service.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/server_metrics.dart';
import 'package:flutter_client/services/storage_service.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_client/models/resource_usage.dart';

class ServerProvider with ChangeNotifier {
  static const Duration statusRefreshInterval = Duration(seconds: 5);

  final ApiService _apiService;
  final WebSocketService _webSocketService;

  List<Server> _servers = [];
  Map<String, ServerMetrics> _serverMetrics = {};
  bool _isLoading = false;
  String? _error;

  // 서버 상태 모니터링을 위한 타이머 관리
  final Map<String, Timer> _monitoringTimers = {};

  // 서버 상태 스트림 컨트롤러
  final _serverStatusController =
      StreamController<Map<String, ServerStatus>>.broadcast();

  Stream<Map<String, ServerStatus>> get serverStatusStream =>
      _serverStatusController.stream;

  ServerProvider({
    required ApiService apiService,
    required WebSocketService webSocketService,
  })  : _apiService = apiService,
        _webSocketService = webSocketService {
    // WebSocket 이벤트 구독
    _webSocketService.metricsStream.listen(_handleMetricsUpdate);
  }

  // 메트릭스 업데이트 처리
// lib/providers/server_provider.dart의 _handleMetricsUpdate 함수 수정 TODO debug
  void _handleMetricsUpdate(ServerMetrics metrics) {
    print('Received metrics update for server: ${metrics.serverId}'); // 로그 추가
    print(
        'Metrics values - CPU: ${metrics.cpuUsage}, Memory: ${metrics.memoryUsage}'); // 로그 추가

    _serverMetrics[metrics.serverId] = metrics;

    final serverIndex = _servers.indexWhere((s) => s.id == metrics.serverId);
    print('Found server at index: $serverIndex'); // 로그 추가

    if (serverIndex != -1) {
      _servers[serverIndex] = _servers[serverIndex].copyWith(
        resources: ResourceUsage(
          cpu: metrics.cpuUsage,
          memory: metrics.memoryUsage,
          disk: metrics.diskUsage,
          network: '${metrics.networkUsage}MB/s',
          lastUpdated: metrics.timestamp,
        ),
      );
      print(
          'Updated server resources: ${_servers[serverIndex].resources}'); // 로그 추가
      notifyListeners();
    }
  }

  // 서버 상태 업데이트
  void _updateServerStatus(String serverId) {
    final metrics = _serverMetrics[serverId];
    if (metrics == null) return;

    final serverIndex = _servers.indexWhere((s) => s.id == serverId);
    if (serverIndex == -1) return;

    final server = _servers[serverIndex];
    ServerStatus newStatus;

    // CPU, 메모리, 디스크 사용량에 따른 상태 결정
    if (metrics.cpuUsage >= AppConstants.criticalThreshold ||
        metrics.memoryUsage >= AppConstants.criticalThreshold ||
        metrics.diskUsage >= AppConstants.criticalThreshold) {
      newStatus = ServerStatus.critical;
    } else if (metrics.cpuUsage >= AppConstants.warningThreshold ||
        metrics.memoryUsage >= AppConstants.warningThreshold ||
        metrics.diskUsage >= AppConstants.warningThreshold) {
      newStatus = ServerStatus.warning;
    } else {
      newStatus = ServerStatus.online;
    }

    if (server.status != newStatus) {
      _servers[serverIndex] = server.copyWith(status: newStatus);
      _serverStatusController.add({serverId: newStatus});
      notifyListeners();
    }
  }

  // 서버 필터링 기능
  List<Server> filterServers({
    String? searchQuery,
    ServerStatus? status,
    ServerType? type,
    ServerCategory? category,
    bool? hasWarnings,
  }) {
    return _servers.where((server) {
      if (searchQuery?.isNotEmpty ?? false) {
        final query = searchQuery!.toLowerCase();
        if (!server.name.toLowerCase().contains(query) &&
            !server.hostname!.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (status != null && server.status != status) return false;
      if (type != null && server.type != type) return false;
      if (category != null && server.category != category) return false;
      if (hasWarnings != null && server.hasWarnings != hasWarnings)
        return false;

      return true;
    }).toList();
  }

  // 서버 모니터링 시작

  void startMonitoring(String serverId) {
    // 이미 모니터링 중인 경우 기존 타이머 취소
    stopMonitoring(serverId);

    // 초기 딜레이 추가
    Future.delayed(const Duration(seconds: 1), () {
      // 새로운 타이머 시작
      _monitoringTimers[serverId] = Timer.periodic(
        statusRefreshInterval,
        (_) => refreshServerStatus(serverId),
      );

      // 웹소켓 구독 시작
      _webSocketService.subscribeToServerMetrics(serverId);
    });
  }

  // 서버 모니터링 중지
  void stopMonitoring(String serverId) {
    _monitoringTimers[serverId]?.cancel();
    _monitoringTimers.remove(serverId);
    _webSocketService.unsubscribeFromServerMetrics(serverId);
  }

  Future<void> addServer({
    required String name,
    required String host,
    required int port,
    required String username,
    required String password,
    required ServerType type,
    required ServerCategory category,
  }) async {
    _setLoading(true);
    try {
      // 1. 서버 연결 테스트
      await testConnection(
        host: host,
        port: port,
        username: username,
        password: password,
      );

      // 2. 토큰 리프레시 시도
      try {
        final response = await _apiService.request(
          path: '/auth/login',
          method: 'POST',
          data: {'email': 'test@example.com', 'password': 'test123'},
        );

        final storage = await StorageService.initialize();
        await storage.setToken(response.data['token']);
        await storage.setRefreshToken(response.data['refresh_token']);

        // 3. 서버 추가 시도
        await _tryAddServer(
            name, host, port, username, password, type, category);
      } catch (authError) {
        // 인증 실패시 기존 토큰으로 시도
        await _tryAddServer(
            name, host, port, username, password, type, category);
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        throw '이미 등록된 서버입니다'; // 사용자 친화적 메시지
      }
      debugPrint('Server add error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _tryAddServer(
    String name,
    String host,
    int port,
    String username,
    String password,
    ServerType type,
    ServerCategory category,
  ) async {
    try {
      final server = await _apiService.addServer(
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        type: type,
        category: category,
      );

      _servers.add(server);
      startMonitoring(server.id);
      notifyListeners();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        throw '이미 등록된 서버입니다';
      }
      rethrow;
    }
  }

  // Future<bool> _checkAndRefreshToken() async {
  //   try {
  //     final storage = await StorageService.initialize();
  //     final token = await storage.getToken();
  //     if (token == null) return false;

  //     final response = await _apiService.request(
  //       path: '/auth/me',
  //       method: 'GET',
  //     );
  //     return response.statusCode == 200;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // 종료 처리
  @override
  void dispose() {
    for (final timer in _monitoringTimers.values) {
      timer.cancel();
    }
    _monitoringTimers.clear();
    _serverStatusController.close();
    super.dispose();
  }

  // 대신 필요한 시점에 명시적으로 호출
  Future<void> initializeData() async {
    await loadServers();
  }

  List<Server> get servers => _servers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadServers() async {
    _setLoading(true);
    try {
      _servers = await _apiService.getServers();
      _error = null;
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  // Future<void> loadServers() async {
  //   try {
  //     _isLoading = true;
  //     _error = null;
  //     notifyListeners();

  //     debugPrint('서버 목록 로딩 시작');
  //     _servers = await _apiService.getServers();
  //     debugPrint('서버 목록 로딩 완료: ${_servers.length}개');

  //     // 각 서버에 대해 한 번만 모니터링 시작
  //     for (final server in _servers) {
  //       // 이미 모니터링 중인 서버는 건너뛰기
  //       if (!_monitoringTimers.containsKey(server.id)) {
  //         startMonitoring(server.id);
  //       }
  //     }

  //     _isLoading = false;
  //     notifyListeners();
  //   } catch (e) {
  //     debugPrint('서버 목록 로딩 실패: $e');
  //     _error = ErrorUtils.getErrorMessage(e);
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // TODO debug
  Future<void> loadServers() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('서버 목록 로딩 시작: 상태 = $_isLoading');
      _servers = await _apiService.getServers();
      debugPrint('서버 데이터: ${_servers.map((s) => s.toJson())}');

      for (final server in _servers) {
        debugPrint('서버 처리: ${server.id}, 타입: ${server.runtimeType}');
        if (!_monitoringTimers.containsKey(server.id)) {
          startMonitoring(server.id);
        }
      }

      _isLoading = false;
      notifyListeners();
      debugPrint('서버 목록 로딩 완료: 상태 = $_isLoading');
    } catch (e, stackTrace) {
      debugPrint('서버 목록 로딩 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      _error = ErrorUtils.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateServer(Server server) async {
    _setLoading(true);
    try {
      final updatedServer = await _apiService.updateServer(server);
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        _servers[index] = updatedServer;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteServer(String serverId) async {
    _setLoading(true);
    try {
      await _apiService.deleteServer(serverId);
      _servers.removeWhere((server) => server.id == serverId);

      // WebSocket 구독 취소
      _webSocketService.unsubscribeFromServerMetrics(serverId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restartServer(String serverId) async {
    _setLoading(true);
    try {
      await _apiService.restartServer(serverId);
      final index = _servers.indexWhere((s) => s.id == serverId);
      if (index != -1) {
        _servers[index] = _servers[index].copyWith(
          status: ServerStatus.warning,
        );
        notifyListeners();
      }
      _error = null;
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshServerStatus(String serverId) async {
    try {
      final response = await _apiService.getServerStatus(serverId);
      if (response != null) {
        // 응답이 있을 때만 업데이트
        final index = _servers.indexWhere((s) => s.id == serverId);
        if (index != -1) {
          _servers[index] = response;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Status refresh failed for server $serverId: $e');
      // 에러가 발생하면 해당 서버의 모니터링만 중지
      stopMonitoring(serverId);
    }
  }

  Future<void> testConnection({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _apiService.testServerConnection(
        host: host,
        port: port,
        username: username,
        password: password,
      );
      _error = null;
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<LogEntry>> fetchLogs({
    String? serverId,
    List<String>? levels,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int limit = 20,
    DateTime? before,
  }) async {
    _setLoading(true);
    try {
      final response = await _apiService.getLogs(
        serverId: serverId,
        levels: levels,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        search: search,
        limit: limit,
        before: before?.toIso8601String(),
      );

      _error = null;
      return (response['logs'] as List)
          .map((log) => LogEntry.fromJson(log))
          .toList();
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<LogEntry>> fetchAllLogs({
    String? serverId,
    List<String>? levels,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    _setLoading(true);
    try {
      final response = await _apiService.getAllLogs(
        serverId: serverId,
        levels: levels,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        search: search,
      );

      _error = null;
      return (response['logs'] as List)
          .map((log) => LogEntry.fromJson(log))
          .toList();
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Map<String, List<int>> _serverTrends = {
    'total': [0, 0, 0, 0, 0],
    'atRisk': [0, 0, 0, 0, 0],
    'safe': [0, 0, 0, 0, 0],
  };

  Map<String, List<int>> get serverTrends => _serverTrends;

  double getAverageCpuUsage() {
    if (_servers.isEmpty) return 0.0;
    final total =
        _servers.fold(0.0, (sum, server) => sum + server.resources.cpu);
    return total / _servers.length;
  }

  double getAverageMemoryUsage() {
    if (_servers.isEmpty) return 0.0;
    final total =
        _servers.fold(0.0, (sum, server) => sum + server.resources.memory);
    return total / _servers.length;
  }

  double getAverageDiskUsage() {
    if (_servers.isEmpty) return 0.0;
    final total =
        _servers.fold(0.0, (sum, server) => sum + server.resources.disk);
    return total / _servers.length;
  }

  Future<void> refreshAll() async {
    _setLoading(true);
    try {
      await _loadServers();
      await _updateTrends();
      _error = null;
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshResourceUsage() async {
    _setLoading(true);
    try {
      for (final server in _servers) {
        await refreshServerStatus(server.id);
      }
      _error = null;
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _updateTrends() async {
    try {
      final trends = await _apiService.getServerTrends();
      _serverTrends = {
        'total': List<int>.from(trends['total'] ?? [0, 0, 0, 0, 0]),
        'atRisk': List<int>.from(trends['at_risk'] ?? [0, 0, 0, 0, 0]),
        'safe': List<int>.from(trends['safe'] ?? [0, 0, 0, 0, 0]),
      };
      notifyListeners();
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
    }
  }

  List<TimeSeriesData> getCombinedResourceHistory(String type) {
    final combined = <TimeSeriesData>[];
    for (final server in _servers) {
      switch (type) {
        case 'cpu':
          combined.addAll(server.resources.cpuHistory);
          break;
        case 'memory':
          combined.addAll(server.resources.memoryHistory);
          break;
        case 'disk':
          combined.addAll(server.resources.diskHistory);
          break;
        case 'network':
          combined.addAll(server.resources.networkHistory);
          break;
      }
    }
    return combined..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> refreshServerData(String serverId) async {
    _setLoading(true);
    try {
      final server = await _apiService.getServerDetails(serverId);
      final index = _servers.indexWhere((s) => s.id == serverId);
      if (index != -1) {
        _servers[index] = server;
        notifyListeners();
      }
      _error = null;
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<FlSpot>> watchCpuMetrics(String serverId, TimeRange timeRange) {
    return _apiService.streamServerMetrics(serverId).map((usage) {
      final history = usage.cpuHistory
          .where((data) => data.timestamp.isAfter(timeRange.startTime))
          .toList();

      // 데이터 포인트 간격을 계산
      final interval = (history.length / 10).ceil();

      return history
          .asMap()
          .entries
          .where((entry) => entry.key % interval == 0)
          .map((entry) => FlSpot(
                entry.key.toDouble(),
                entry.value.value,
              ))
          .toList();
    });
  }

  Stream<List<FlSpot>> watchMemoryMetrics(
      String serverId, TimeRange timeRange) {
    return _apiService.streamServerMetrics(serverId).map((usage) {
      final history = usage.memoryHistory
          .where((data) => data.timestamp.isAfter(timeRange.startTime))
          .toList();

      final interval = (history.length / 10).ceil();

      return history
          .asMap()
          .entries
          .where((entry) => entry.key % interval == 0)
          .map((entry) => FlSpot(
                entry.key.toDouble(),
                entry.value.value,
              ))
          .toList();
    });
  }

  Stream<List<FlSpot>> watchDiskMetrics(String serverId, TimeRange timeRange) {
    return _apiService.streamServerMetrics(serverId).map((usage) {
      final history = usage.diskHistory
          .where((data) => data.timestamp.isAfter(timeRange.startTime))
          .toList();

      final interval = (history.length / 10).ceil();

      return history
          .asMap()
          .entries
          .where((entry) => entry.key % interval == 0)
          .map((entry) => FlSpot(
                entry.key.toDouble(),
                entry.value.value,
              ))
          .toList();
    });
  }

  Stream<List<FlSpot>> watchNetworkMetrics(
      String serverId, TimeRange timeRange) {
    return _apiService.streamServerMetrics(serverId).map((usage) {
      final history = usage.networkHistory
          .where((data) => data.timestamp.isAfter(timeRange.startTime))
          .toList();

      final interval = (history.length / 10).ceil();

      return history
          .asMap()
          .entries
          .where((entry) => entry.key % interval == 0)
          .map((entry) => FlSpot(
                entry.key.toDouble(),
                entry.value.value,
              ))
          .toList();
    });
  }
}
