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
import 'package:flutter_client/models/api_response.dart';
import 'dart:async';
import 'package:flutter_client/services/websocket_service.dart';

class ServerProvider with ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _webSocketService; // 추가

  List<Server> _servers = [];
  bool _isLoading = false;
  String? _error;

  ServerProvider({
    required ApiService apiService,
    required WebSocketService webSocketService, // 생성자 매개변수 추가
  })  : _apiService = apiService,
        _webSocketService = webSocketService;

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

  Future<void> addServer({
    required String name,
    required String host,
    required int port,
    required String username,
    required String password,
    required String type,
  }) async {
    _setLoading(true);
    try {
      debugPrint('서버 추가 요청 데이터: {');
      debugPrint('  name: $name,');
      debugPrint('  host: $host,');
      debugPrint('  port: $port,');
      debugPrint('  username: $username,');
      debugPrint('  type: $type');
      debugPrint('}');

      final server = await _apiService.addServer(
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        type: type,
      );

      // 응답 데이터 로깅
      debugPrint('서버 응답 데이터: ${server.toJson()}');

      // 서버 목록에 추가
      _servers.add(server);

      // WebSocket 연결 설정
      _webSocketService.subscribeToServerMetrics(server.id);

      // 서버 상태 모니터링 시작
      _startServerMonitoring(server.id);

      // 전체 서버 목록 새로고침
      await loadServers();

      _error = null;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('서버 추가 에러: $e');
      debugPrint('스택 트레이스: $stackTrace');
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _startServerMonitoring(String serverId) {
    // 서버 상태 주기적 체크
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_servers.any((s) => s.id == serverId)) {
        refreshServerStatus(serverId);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> loadServers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('서버 목록 로딩 시작');
      _servers = await _apiService.getServers();
      debugPrint('서버 목록 로딩 완료: ${_servers.length}개');

      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('API 예외 발생: ${e.message}');
      _error = e.message;
      notifyListeners();
    } catch (e) {
      debugPrint('예상치 못한 예외 발생: $e');
      _error = '서버 목록을 불러오는데 실패했습니다: $e';
      notifyListeners();
    } finally {
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
      final status = await _apiService.getServerStatus(serverId);
      final index = _servers.indexWhere((s) => s.id == serverId);
      if (index != -1) {
        _servers[index] = _servers[index].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
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
