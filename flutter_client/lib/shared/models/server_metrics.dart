// lib/shared/models/server_metrics.dart

import 'process_info.dart';

class ServerMetrics {
  final double cpu;
  final double memory;
  final double disk;
  final double network;
  final String uptime;
  final List<ProcessInfo> processes;

  const ServerMetrics({
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.network,
    required this.uptime,
    this.processes = const [],
  });

  factory ServerMetrics.fromJson(Map<String, dynamic> json) {
    return ServerMetrics(
      cpu: json['cpu'].toDouble(),
      memory: json['memory'].toDouble(),
      disk: json['disk'].toDouble(),
      network: json['network'].toDouble(),
      uptime: json['uptime'],
      processes: (json['processes'] as List?)
              ?.map((p) => ProcessInfo.fromJson(p))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'cpu': cpu,
        'memory': memory,
        'disk': disk,
        'network': network,
        'uptime': uptime,
        'processes': processes.map((p) => p.toJson()).toList(),
      };
}
