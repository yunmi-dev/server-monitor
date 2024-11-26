// lib/providers/server_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/utils/error_utils.dart';

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
}
