// lib/models/server.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';
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
  final String? hostname;
  final int? port;
  final String? username;
  final ServerType type; // OS type (linux, windows, mac os)
  final ServerCategory category;

  const Server({
    required this.id,
    required this.name,
    required this.status,
    required this.resources,
    required this.uptime,
    required this.processes,
    required this.recentLogs,
    this.hostname,
    this.port,
    this.username,
    this.type = ServerType.linux,
    this.category = ServerCategory.physical,
  });

  bool get isOnline => status == ServerStatus.online;

  bool get hasWarnings =>
      status == ServerStatus.warning ||
      status == ServerStatus.critical ||
      resources.hasWarning;

  String? get host => hostname;

  factory Server.fromJson(Map<String, dynamic> json) {
    print('Server fromJson raw data: $json'); // 로깅 추가 TODO

    try {
      // id 처리
      String serverId = json['id'].toString();
      print('Parsed serverId: $serverId'); // 로깅 추가

      print('Parsing status from: ${json['status']}'); // 로깅 추가
      print('Parsing resources from: ${json['resources']}'); // 로깅 추가
      print('Parsing processes from: ${json['processes']}'); // 로깅 추가

      final server = Server(
        id: serverId,
        name: json['name'] ?? 'Unknown',
        status: ServerStatus.fromString(json['status'] ?? 'offline'),
        resources: json['resources'] != null
            ? ResourceUsage.fromJson(json['resources'])
            : ResourceUsage.empty(),
        uptime: json['uptime'] ?? '0s',
        processes: (json['processes'] as List?)
                ?.map((p) => Process.fromJson(p))
                .toList() ??
            [],
        recentLogs: (json['recent_logs'] as List?)
                ?.map((log) => LogEntry.fromJson(log))
                .toList() ??
            [],
        hostname: json['hostname'] ?? json['host'],
        port: json['port'],
        username: json['username'],
        type: json['type'] != null
            ? ServerType.fromJson(json['type'])
            : ServerType.linux,
        category: json['category'] != null
            ? ServerCategory.fromJson(json['category'])
            : ServerCategory.physical,
      );

      print('Successfully created Server object: ${server.toJson()}'); // 로깅 추가
      return server;
    } catch (e, stack) {
      print('Error in Server.fromJson: $e'); // 로깅 추가
      print('Stack trace: $stack'); // 로깅 추가
      rethrow;
    }
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
      'hostname': hostname,
      'port': port,
      'username': username,
      'type': type.toJson(),
      'category': category.toJson(),
    };
  }

  Server copyWith({
    String? id,
    String? name,
    ServerStatus? status,
    ResourceUsage? resources,
    String? uptime,
    List<Process>? processes,
    List<LogEntry>? recentLogs,
    String? hostname,
    int? port,
    String? username,
    ServerType? osType,
    ServerType? serverType,
    ServerType? type,
    ServerCategory? category,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      resources: resources ?? this.resources,
      uptime: uptime ?? this.uptime,
      processes: processes ?? this.processes,
      recentLogs: recentLogs ?? this.recentLogs,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      type: type ?? this.type,
      category: category ?? this.category,
    );
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
