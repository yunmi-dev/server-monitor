// lib/models/server.dart
import 'package:flutter/material.dart';
import 'process.dart';
import 'resource_usage.dart';
import 'log_entry.dart';

class Server {
  final String id;
  final String name;
  final ServerStatus status;
  final ResourceUsage resources;
  final String uptime;
  final List<Process> processes;
  final List<LogEntry> recentLogs;
  final String? host;
  final int? port;
  final String? username;
  final String? type;

  const Server({
    required this.id,
    required this.name,
    required this.status,
    required this.resources,
    required this.uptime,
    required this.processes,
    required this.recentLogs,
    this.host,
    this.port,
    this.username,
    this.type,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'],
      name: json['name'],
      status: ServerStatus.fromString(json['status']),
      resources: ResourceUsage.fromJson(json['resources']),
      uptime: json['uptime'],
      processes:
          (json['processes'] as List).map((p) => Process.fromJson(p)).toList(),
      recentLogs: (json['recent_logs'] as List)
          .map((log) => LogEntry.fromJson(log))
          .toList(),
      host: json['host'],
      port: json['port'],
      username: json['username'],
      type: json['type'],
    );
  }

  Server copyWith({
    String? id,
    String? name,
    ServerStatus? status,
    ResourceUsage? resources,
    String? uptime,
    List<Process>? processes,
    List<LogEntry>? recentLogs,
    String? host,
    int? port,
    String? username,
    String? type,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      resources: resources ?? this.resources,
      uptime: uptime ?? this.uptime,
      processes: processes ?? this.processes,
      recentLogs: recentLogs ?? this.recentLogs,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.toString().split('.').last,
      'resources': resources.toJson(),
      'uptime': uptime,
      'processes': processes.map((p) => p.toJson()).toList(),
      'recent_logs': recentLogs.map((log) => log.toJson()).toList(),
      'host': host,
      'port': port,
      'username': username,
      'type': type,
    };
  }
}

enum ServerStatus {
  online,
  offline,
  warning,
  critical;

  static ServerStatus fromString(String status) {
    return ServerStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => ServerStatus.offline,
    );
  }

  Color get color {
    switch (this) {
      case ServerStatus.online:
        return Colors.green;
      case ServerStatus.offline:
        return Colors.red;
      case ServerStatus.warning:
        return Colors.orange;
      case ServerStatus.critical:
        return Colors.red;
    }
  }
}
