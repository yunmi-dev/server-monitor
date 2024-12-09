// lib/models/process.dart
import 'package:flutter/material.dart';

/*
final process = Process(
  pid: 1234,
  name: 'nginx',
  user: 'www-data',
  cpuUsage: 25.0,
  memoryUsage: 512.0,
  threadCount: 4,
  status: 'running',
  startTime: DateTime.now(),
  command: 'nginx -g daemon off;'
);
*/

class Process {
  final int pid;
  final String name;
  final String user;
  final double cpuUsage;
  final double memoryUsage;
  final int threadCount;
  final String status;
  final DateTime startTime;
  final String command;
  final Map<String, double> resourceHistory;
  final bool isSystem;
  final String? parentProcessName;
  final int? parentPid;
  final List<int> childPids;
  final double diskReadRate;
  final double diskWriteRate;
  final double networkReceiveRate;
  final double networkSendRate;
  final String? workingDirectory;
  final Map<String, String> environment;

  Process({
    required this.pid,
    required this.name,
    required this.user,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.threadCount,
    required this.status,
    required this.startTime,
    required this.command,
    this.resourceHistory = const {},
    this.isSystem = false,
    this.parentProcessName,
    this.parentPid,
    this.childPids = const [],
    this.diskReadRate = 0.0,
    this.diskWriteRate = 0.0,
    this.networkReceiveRate = 0.0,
    this.networkSendRate = 0.0,
    this.workingDirectory,
    this.environment = const {},
  });

  String get uptime {
    final now = DateTime.now();
    final difference = now.difference(startTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
    return '${difference.inMinutes}m';
  }

  String get formattedMemoryUsage {
    if (memoryUsage >= 1024) {
      return '${(memoryUsage / 1024).toStringAsFixed(1)} GB';
    }
    return '${memoryUsage.toStringAsFixed(1)} MB';
  }

  String get formattedDiskRead => _formatByteRate(diskReadRate);
  String get formattedDiskWrite => _formatByteRate(diskWriteRate);
  String get formattedNetworkReceive => _formatByteRate(networkReceiveRate);
  String get formattedNetworkSend => _formatByteRate(networkSendRate);

  String _formatByteRate(double bytesPerSecond) {
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${bytesPerSecond.toStringAsFixed(1)} B/s';
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'sleeping':
        return Colors.blue;
      case 'stopped':
        return Colors.orange;
      case 'zombie':
        return Colors.red;
      case 'idle':
        return Colors.grey;
      case 'waiting':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'running':
        return Icons.play_arrow;
      case 'sleeping':
        return Icons.pause;
      case 'stopped':
        return Icons.stop;
      case 'zombie':
        return Icons.warning;
      case 'idle':
        return Icons.hourglass_empty;
      case 'waiting':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  int get priority {
    if (isSystem) return 0;
    if (cpuUsage > 80 || memoryUsage > 80) return 1;
    if (cpuUsage > 50 || memoryUsage > 50) return 2;
    return 3;
  }

  double? get cpuTrend {
    if (resourceHistory.isEmpty) return null;
    final values = resourceHistory.values.toList();
    if (values.length < 2) return 0;
    return values.last - values[values.length - 2];
  }

  bool get isPotentiallyProblematic {
    return cpuUsage > 80 ||
        memoryUsage > 80 ||
        status.toLowerCase() == 'zombie' ||
        (cpuTrend ?? 0) > 20;
  }

  String get processType {
    if (isSystem) return 'System Process';
    if (name.toLowerCase().contains('daemon')) return 'Daemon';
    if (parentPid == null) return 'Parent Process';
    if (childPids.isNotEmpty) return 'Parent Process';
    return 'User Process';
  }

  // JSON Serialization
  factory Process.fromJson(Map<String, dynamic> json) {
    return Process(
      pid: json['pid'] as int,
      name: json['name'] as String,
      // 실제 서버 응답에 없는 필드들은 기본값 제공
      user: json['user'] ?? 'unknown', // 기본값 추가
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      threadCount: json['threadCount'] ?? 1, // 기본값 추가
      status: json['status'] ?? 'unknown', // 기본값 추가
      startTime: DateTime.now(), // 현재 시간으로 기본값
      command: json['command'] ?? '', // 기본값 추가
      resourceHistory:
          Map<String, double>.from(json['resourceHistory'] as Map? ?? {}),
      isSystem: json['isSystem'] as bool? ?? false,
      parentProcessName: json['parentProcessName'] as String?,
      parentPid: json['parentPid'] as int?,
      childPids: List<int>.from(json['childPids'] as List? ?? []),
      diskReadRate: (json['diskReadRate'] as num?)?.toDouble() ?? 0.0,
      diskWriteRate: (json['diskWriteRate'] as num?)?.toDouble() ?? 0.0,
      networkReceiveRate:
          (json['networkReceiveRate'] as num?)?.toDouble() ?? 0.0,
      networkSendRate: (json['networkSendRate'] as num?)?.toDouble() ?? 0.0,
      workingDirectory: json['workingDirectory'] as String?,
      environment: Map<String, String>.from(json['environment'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'name': name,
      'user': user,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'threadCount': threadCount,
      'status': status,
      'startTime': startTime.toIso8601String(),
      'command': command,
      'resourceHistory': resourceHistory,
      'isSystem': isSystem,
      'parentProcessName': parentProcessName,
      'parentPid': parentPid,
      'childPids': childPids,
      'diskReadRate': diskReadRate,
      'diskWriteRate': diskWriteRate,
      'networkReceiveRate': networkReceiveRate,
      'networkSendRate': networkSendRate,
      'workingDirectory': workingDirectory,
      'environment': environment,
    };
  }

  // Copying with modifications
  Process copyWith({
    int? pid,
    String? name,
    String? user,
    double? cpuUsage,
    double? memoryUsage,
    int? threadCount,
    String? status,
    DateTime? startTime,
    String? command,
    Map<String, double>? resourceHistory,
    bool? isSystem,
    String? parentProcessName,
    int? parentPid,
    List<int>? childPids,
    double? diskReadRate,
    double? diskWriteRate,
    double? networkReceiveRate,
    double? networkSendRate,
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    return Process(
      pid: pid ?? this.pid,
      name: name ?? this.name,
      user: user ?? this.user,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      threadCount: threadCount ?? this.threadCount,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      command: command ?? this.command,
      resourceHistory: resourceHistory ?? this.resourceHistory,
      isSystem: isSystem ?? this.isSystem,
      parentProcessName: parentProcessName ?? this.parentProcessName,
      parentPid: parentPid ?? this.parentPid,
      childPids: childPids ?? this.childPids,
      diskReadRate: diskReadRate ?? this.diskReadRate,
      diskWriteRate: diskWriteRate ?? this.diskWriteRate,
      networkReceiveRate: networkReceiveRate ?? this.networkReceiveRate,
      networkSendRate: networkSendRate ?? this.networkSendRate,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      environment: environment ?? this.environment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Process &&
          runtimeType == other.runtimeType &&
          pid == other.pid &&
          name == other.name &&
          user == other.user &&
          cpuUsage == other.cpuUsage &&
          memoryUsage == other.memoryUsage &&
          threadCount == other.threadCount &&
          status == other.status &&
          startTime == other.startTime &&
          command == other.command;

  @override
  int get hashCode =>
      pid.hashCode ^
      name.hashCode ^
      user.hashCode ^
      cpuUsage.hashCode ^
      memoryUsage.hashCode ^
      threadCount.hashCode ^
      status.hashCode ^
      startTime.hashCode ^
      command.hashCode;
}
