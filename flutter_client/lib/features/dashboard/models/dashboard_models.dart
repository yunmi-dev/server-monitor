// lib/features/dashboard/models/dashboard_models.dart

class ServerStatus {
  final String id;
  final String name;
  final bool isOnline;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;

  ServerStatus({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      id: json['id'],
      name: json['name'],
      isOnline: json['isOnline'],
      cpuUsage: json['cpuUsage'].toDouble(),
      memoryUsage: json['memoryUsage'].toDouble(),
      diskUsage: json['diskUsage'].toDouble(),
    );
  }
}

class ProcessInfo {
  final String name;
  final double cpuUsage;
  final double memoryUsage;
  final String networkUsage;

  ProcessInfo({
    required this.name,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkUsage,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      name: json['name'],
      cpuUsage: json['cpuUsage'].toDouble(),
      memoryUsage: json['memoryUsage'].toDouble(),
      networkUsage: json['networkUsage'],
    );
  }
}
