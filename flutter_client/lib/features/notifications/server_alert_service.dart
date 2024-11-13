// lib/features/notifications/server_alert_service.dart

import '../../shared/models/server.dart';

class ServerAlertService {
  final Function(ServerAlert) onAlert;

  ServerAlertService({required this.onAlert});

  void startMonitoring(List<Server> servers) {
    for (final server in servers) {
      _monitorServer(server);
    }
  }

  void _monitorServer(Server server) {
    // CPU 사용량 모니터링
    if (server.metrics.cpu > 90) {
      onAlert(ServerAlert(
        serverId: server.id,
        title: 'High CPU Usage',
        message:
            '${server.name} CPU usage is critical (${server.metrics.cpu.toStringAsFixed(1)}%)',
        type: AlertType.critical,
      ));
    } else if (server.metrics.cpu > 80) {
      onAlert(ServerAlert(
        serverId: server.id,
        title: 'CPU Warning',
        message:
            '${server.name} CPU usage is high (${server.metrics.cpu.toStringAsFixed(1)}%)',
        type: AlertType.warning,
      ));
    }

    // 메모리 사용량 모니터링
    if (server.metrics.memory > 90) {
      onAlert(ServerAlert(
        serverId: server.id,
        title: 'High Memory Usage',
        message:
            '${server.name} memory usage is critical (${server.metrics.memory.toStringAsFixed(1)}%)',
        type: AlertType.critical,
      ));
    }

    // 디스크 사용량 모니터링
    if (server.metrics.disk > 95) {
      onAlert(ServerAlert(
        serverId: server.id,
        title: 'Disk Space Critical',
        message:
            '${server.name} disk usage is critical (${server.metrics.disk.toStringAsFixed(1)}%)',
        type: AlertType.critical,
      ));
    }
  }
}

class ServerAlert {
  final String serverId;
  final String title;
  final String message;
  final AlertType type;
  final DateTime timestamp;

  ServerAlert({
    required this.serverId,
    required this.title,
    required this.message,
    required this.type,
  }) : timestamp = DateTime.now();
}

enum AlertType {
  info,
  warning,
  critical,
}
