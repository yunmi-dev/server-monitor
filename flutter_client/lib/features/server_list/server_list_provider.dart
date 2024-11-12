// lib/features/server_list/server_list_provider.dart

import 'package:flutter/material.dart';
import '../../shared/models/server.dart';
import '../../shared/models/server_metrics.dart';
import '../../shared/models/process_info.dart';

class ServerListProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  final List<Server> _servers = [];
  final Map<String, bool> _filters = {
    'production': false,
    'development': false,
    'staging': false,
  };

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<Server> get filteredServers => _filterServers();
  Map<String, bool> get filters => Map.unmodifiable(_filters);

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateFilters(Map<String, bool> newFilters) {
    _filters.addAll(newFilters);
    notifyListeners();
  }

  List<Server> _filterServers() {
    var filtered = _servers;

    // 검색어 필터링
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((server) {
        final searchLower = _searchQuery.toLowerCase();
        return server.name.toLowerCase().contains(searchLower) ||
            server.type.toLowerCase().contains(searchLower) ||
            server.location.toLowerCase().contains(searchLower);
      }).toList();
    }

    // 타입 필터링
    if (_filters.values.any((isSelected) => isSelected)) {
      filtered = filtered.where((server) {
        final serverType = server.type.toLowerCase();
        return _filters.entries.any((entry) =>
            entry.value && serverType.contains(entry.key.toLowerCase()));
      }).toList();
    }

    return filtered;
  }

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // 실제 API 호출 시 제거

      // 개발용 더미 데이터
      _servers.clear();
      _servers.addAll([
        Server(
          id: '1',
          name: 'Production Server 1',
          isOnline: true,
          type: 'Production',
          location: 'US-East',
          metrics: const ServerMetrics(
            cpu: 45.0,
            memory: 60.0,
            disk: 75.0,
            network: 30.0,
            uptime: '15d 7h',
            processes: [
              ProcessInfo(
                name: 'nginx',
                cpu: 2.5,
                memory: 1.8,
                network: '150MB/s',
                pid: 1234,
              ),
              ProcessInfo(
                name: 'mongodb',
                cpu: 4.2,
                memory: 3.1,
                network: '80MB/s',
                pid: 1235,
              ),
            ],
          ),
        ),
        Server(
          id: '2',
          name: 'Development Server',
          isOnline: true,
          type: 'Development',
          location: 'US-West',
          metrics: const ServerMetrics(
            cpu: 30.0,
            memory: 40.0,
            disk: 50.0,
            network: 25.0,
            uptime: '7d 12h',
            processes: [
              ProcessInfo(
                name: 'nodejs',
                cpu: 1.5,
                memory: 1.2,
                network: '50MB/s',
                pid: 1236,
              ),
              ProcessInfo(
                name: 'redis',
                cpu: 1.0,
                memory: 0.8,
                network: '20MB/s',
                pid: 1237,
              ),
            ],
          ),
        ),
        Server(
          id: '3',
          name: 'Staging Server',
          isOnline: false,
          type: 'Staging',
          location: 'EU-West',
          metrics: const ServerMetrics(
            cpu: 0.0,
            memory: 0.0,
            disk: 0.0,
            network: 0.0,
            uptime: '0d 0h',
            processes: [],
          ),
        ),
      ]);
    } catch (e) {
      _error = 'Failed to load servers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addServer({
    required String name,
    required String type,
    required String location,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: 실제 API 호출로 대체
      await Future.delayed(const Duration(seconds: 1));

      final newServer = Server(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        isOnline: true,
        type: type,
        location: location,
        metrics: const ServerMetrics(
          cpu: 0.0,
          memory: 0.0,
          disk: 0.0,
          network: 0.0,
          uptime: '0d 0h',
          processes: [],
        ),
      );

      _servers.add(newServer);
    } catch (e) {
      _error = 'Failed to add server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeServer(String serverId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: 실제 API 호출로 대체
      await Future.delayed(const Duration(seconds: 1));

      _servers.removeWhere((server) => server.id == serverId);
    } catch (e) {
      _error = 'Failed to remove server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
