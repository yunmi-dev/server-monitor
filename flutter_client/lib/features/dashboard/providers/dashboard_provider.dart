// lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

class DashboardProvider extends ChangeNotifier {
  List<ServerStatus> _servers = [];
  List<ProcessInfo> _processes = [];
  bool _isLoading = false;

  List<ServerStatus> get servers => _servers;
  List<ProcessInfo> get processes => _processes;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: 실제 API 연동
      await Future.delayed(Duration(seconds: 1));

      // 임시 데이터
      _servers = [
        ServerStatus(
          id: '1',
          name: 'Server 1',
          isOnline: true,
          cpuUsage: 45.0,
          memoryUsage: 60.0,
          diskUsage: 75.0,
        ),
        ServerStatus(
          id: '2',
          name: 'Server 2',
          isOnline: true,
          cpuUsage: 30.0,
          memoryUsage: 40.0,
          diskUsage: 50.0,
        ),
      ];

      _processes = [
        ProcessInfo(
          name: 'nginx',
          cpuUsage: 2.5,
          memoryUsage: 1.8,
          networkUsage: '150MB/s',
        ),
        ProcessInfo(
          name: 'mongodb',
          cpuUsage: 4.2,
          memoryUsage: 3.1,
          networkUsage: '80MB/s',
        ),
      ];
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
