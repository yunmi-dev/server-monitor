// lib/providers/server_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/utils/error_utils.dart';
import 'package:flutter_client/models/time_series_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_client/models/time_range.dart';

class ServerProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Server> _servers = [];
  bool _isLoading = false;
  String? _error;

  ServerProvider({
    required ApiService apiService,
  }) : _apiService = apiService {
    _loadServers();
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
      final server = await _apiService.addServer(
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        type: type,
      );
      _servers.add(server);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = ErrorUtils.getErrorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
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
