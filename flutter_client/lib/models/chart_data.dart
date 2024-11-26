// lib/models/chart_data.dart
import 'package:equatable/equatable.dart';

class DistributionData extends Equatable {
  final String timestamp;
  final List<double> values;
  final List<String> categories;

  const DistributionData({
    required this.timestamp,
    required this.values,
    required this.categories,
  });

  factory DistributionData.fromJson(Map<String, dynamic> json) {
    return DistributionData(
      timestamp: json['timestamp'] as String,
      values: (json['values'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'values': values,
      'categories': categories,
    };
  }

  @override
  List<Object> get props => [timestamp, values, categories];
}

class ResourceMetrics extends Equatable {
  final String serverName;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final String status;
  final DateTime timestamp;

  const ResourceMetrics({
    required this.serverName,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.status,
    required this.timestamp,
  });

  factory ResourceMetrics.fromJson(Map<String, dynamic> json) {
    return ResourceMetrics(
      serverName: json['server_name'] as String,
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      memoryUsage: (json['memory_usage'] as num).toDouble(),
      diskUsage: (json['disk_usage'] as num).toDouble(),
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_name': serverName,
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'disk_usage': diskUsage,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
        serverName,
        cpuUsage,
        memoryUsage,
        diskUsage,
        status,
        timestamp,
      ];
}
