// lib/features/server_list/server_list_provider.dart

import 'package:flutter/material.dart';
import '../../shared/models/server.dart';
import '../../shared/models/server_metrics.dart';
import '../../shared/models/process_info.dart';

class ServerListProvider extends ChangeNotifier {
  final List<Server> _servers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;

  List<Server> get servers => _filterServers();
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Server> _filterServers() {
    if (_searchQuery.isEmpty) return _servers;
    return _servers
        .where((server) =>
            server.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            server.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            server.location.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> fetchServers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _servers.clear();
      _servers.addAll([
        Server(
          id: '1',
          name: 'Production Server 1',
          isOnline: true,
          type: 'Production',
          location: 'US-East',
          metrics: ServerMetrics(
            cpu: 45.0,
            memory: 60.0,
            disk: 75.0,
            network: 30.0,
            uptime: '15d 7h',
            processes: const [
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
          metrics: ServerMetrics(
            cpu: 30.0,
            memory: 40.0,
            disk: 50.0,
            network: 25.0,
            uptime: '7d 12h',
            processes: const [
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
}
