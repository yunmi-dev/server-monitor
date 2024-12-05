// lib/models/server.dart
import 'package:flutter/material.dart';
import 'process.dart';
import 'resource_usage.dart';
import 'log_entry.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class Server {
  final String id;
  final String name;
  final ServerStatus status;
  final ResourceUsage resources;
  final String uptime;
  final List<Process> processes;
  final List<LogEntry> recentLogs;
  final String? hostname; // host 대신 hostname 사용 (백엔드와 일치)
  final int? port;
  final String? username;
  final ServerType serverType; // serverType 사용

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
    this.serverType = ServerType.physical, // 기본값 설정
  });

  // 필요한 getter들 추가
  bool get isOnline => status == ServerStatus.online;

  bool get hasWarnings =>
      status == ServerStatus.warning ||
      status == ServerStatus.critical ||
      resources.hasWarning;

  // host getter 추가 (hostname의 별칭)
  String? get host => hostname;

  // type getter 추가 (serverType을 String으로 변환)
  String get type => serverType.toString().split('.').last;

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] ?? '',
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
      serverType: json['server_type'] != null
          ? ServerType.fromString(json['server_type'])
          : ServerType.physical,
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
      'hostname': hostname,
      'port': port,
      'username': username,
      'server_type': serverType.toJson(),
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
    ServerType? serverType,
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
      serverType: serverType ?? this.serverType,
    );
  }
}

enum ServerType {
  physical,
  virtual,
  container;

  static ServerType fromString(String type) {
    return ServerType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == type.toLowerCase(),
      orElse: () => ServerType.physical,
    );
  }

  String toJson() {
    final enumString = toString().split('.').last;
    return '${enumString[0].toUpperCase()}${enumString.substring(1).toLowerCase()}';
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
