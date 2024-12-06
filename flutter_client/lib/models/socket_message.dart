// lib/models/socket_message.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/models/server_metrics.dart';

part 'socket_message.g.dart';

@immutable
enum MessageType {
  @JsonValue('server_status')
  serverStatus,

  @JsonValue('resource_metrics')
  resourceMetrics,

  @JsonValue('alert')
  alert,

  @JsonValue('process_info')
  processInfo,

  @JsonValue('log_entry')
  logEntry,

  @JsonValue('system_info')
  systemInfo,

  @JsonValue('error')
  error,

  @JsonValue('ping')
  ping,

  @JsonValue('pong')
  pong,

  @JsonValue('log')
  log,

  @JsonValue('unknown')
  unknown; // 추가된 unknown 타입

  String get value => _$MessageTypeEnumMap[this]!;
}

/// 알림 메시지의 심각도 레벨 정의
@immutable
enum AlertSeverity {
  @JsonValue('critical')
  critical,

  @JsonValue('warning')
  warning,

  @JsonValue('info')
  info
}

/// WebSocket을 통해 전송되는 메시지의 기본 구조
@immutable
@JsonSerializable(explicitToJson: true)
class SocketMessage extends Equatable {
  final MessageType type;
  final Map<String, dynamic> data;

  @JsonKey(
    fromJson: DateTime.parse,
    toJson: _dateToIso8601String,
  )
  final DateTime timestamp;

  const SocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  /// JSON 직렬화를 위한 팩토리 생성자
  factory SocketMessage.fromJson(dynamic json) {
    try {
      final Map<String, dynamic> messageData =
          json is String ? jsonDecode(json) : Map<String, dynamic>.from(json);

      return _$SocketMessageFromJson(messageData);
    } on FormatException catch (e) {
      debugPrint('Invalid message format: $e');
      rethrow;
    }
  }

  /// 서버 상태 메시지 생성
  factory SocketMessage.serverStatus({
    required String serverId,
    required bool isOnline,
    required Map<String, num> metrics,
    DateTime? timestamp,
  }) {
    return SocketMessage(
      type: MessageType.serverStatus,
      data: {
        'serverId': serverId,
        'isOnline': isOnline,
        'metrics': metrics,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// 리소스 메트릭 메시지 생성
  factory SocketMessage.resourceMetrics({
    required String serverId,
    required ResourceMetrics metrics,
    DateTime? timestamp,
  }) {
    return SocketMessage(
      type: MessageType.resourceMetrics,
      data: metrics.toJson()..addAll({'serverId': serverId}),
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// 알림 메시지 생성
  factory SocketMessage.alert({
    required String serverId,
    required AlertSeverity severity,
    required String message,
    String? category,
    DateTime? timestamp,
  }) {
    return SocketMessage(
      type: MessageType.alert,
      data: {
        'serverId': serverId,
        'severity': severity.name,
        'message': message,
        if (category != null) 'category': category,
      },
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// 프로세스 정보 메시지 생성
  factory SocketMessage.processInfo({
    required String serverId,
    required List<ProcessInfo> processes,
    DateTime? timestamp,
  }) {
    return SocketMessage(
      type: MessageType.processInfo,
      data: {
        'serverId': serverId,
        'processes': processes.map((p) => p.toJson()).toList(),
      },
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Ping 메시지 생성
  factory SocketMessage.ping() {
    return SocketMessage(
      type: MessageType.ping,
      data: const {},
      timestamp: DateTime.now(),
    );
  }

  /// Pong 메시지 생성
  factory SocketMessage.pong() {
    return SocketMessage(
      type: MessageType.pong,
      data: const {},
      timestamp: DateTime.now(),
    );
  }

  factory SocketMessage.log({
    required String serverId,
    required LogEntry logEntry,
    DateTime? timestamp,
  }) {
    return SocketMessage(
      type: MessageType.log,
      data: {
        'serverId': serverId,
        'logEntry': logEntry.toJson(),
      },
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // 기존 메서드들에 로그 관련 getter 추가
  bool get isLog => type == MessageType.log;
  LogEntry? get asLogEntry =>
      isLog ? LogEntry.fromJson(data['logEntry']) : null;

  /// JSON 직렬화
  Map<String, dynamic> toJson() => _$SocketMessageToJson(this);

  /// 메시지 유효성 검사
  bool isValid() {
    if (timestamp.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return false;
    }
    if (timestamp.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  /// 유틸리티 getter들
  bool get isError => type == MessageType.error;
  bool get isAlert => type == MessageType.alert;
  bool get isPing => type == MessageType.ping;
  bool get isPong => type == MessageType.pong;
  bool get isCriticalAlert =>
      isAlert && data['severity'] == AlertSeverity.critical.name;

  /// Deep copy with parameters
  SocketMessage copyWith({
    MessageType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return SocketMessage(
      type: type ?? this.type,
      data: data ?? Map<String, dynamic>.from(this.data),
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [type, data, timestamp];

  @override
  String toString() => 'SocketMessage(type: ${type.name}, '
      'timestamp: ${timestamp.toIso8601String()}, '
      'data: $data)';

  static String _dateToIso8601String(DateTime date) => date.toIso8601String();
}

/// 서버 리소스 메트릭 데이터 모델
@immutable
@JsonSerializable()
class ResourceMetrics extends Equatable {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkUsage;
  final Map<String, num>? additionalMetrics;

  const ResourceMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkUsage,
    this.additionalMetrics,
  });

  factory ResourceMetrics.fromJson(Map<String, dynamic> json) =>
      _$ResourceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceMetricsToJson(this);

  @override
  List<Object?> get props => [
        cpuUsage,
        memoryUsage,
        diskUsage,
        networkUsage,
        additionalMetrics,
      ];
}

// 서버에서 받는 메트릭 데이터를 위한 전용 모델
@immutable
@JsonSerializable()
class ServerMetricsData extends Equatable {
  final double cpuUsage;
  final double diskUsage;
  final double memoryUsage;
  final double networkUsage;
  final int processCount;
  final List<ServerProcess> processes;
  final String serverId;

  @JsonKey(fromJson: DateTime.parse, toJson: _dateToIso8601String)
  final DateTime timestamp;

  const ServerMetricsData({
    required this.cpuUsage,
    required this.diskUsage,
    required this.memoryUsage,
    required this.networkUsage,
    required this.processCount,
    required this.processes,
    required this.serverId,
    required this.timestamp,
  });

  factory ServerMetricsData.fromJson(Map<String, dynamic> json) =>
      _$ServerMetricsDataFromJson(json);

  Map<String, dynamic> toJson() => _$ServerMetricsDataToJson(this);

  @override
  List<Object?> get props => [
        cpuUsage,
        diskUsage,
        memoryUsage,
        networkUsage,
        processCount,
        processes,
        serverId,
        timestamp,
      ];

  static String _dateToIso8601String(DateTime date) => date.toIso8601String();
}

// 서버 프로세스 정보
@immutable
@JsonSerializable()
class ServerProcess extends Equatable {
  final double cpuUsage;
  final int memoryUsage;
  final String name;
  final int pid;

  const ServerProcess({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.name,
    required this.pid,
  });

  factory ServerProcess.fromJson(Map<String, dynamic> json) =>
      _$ServerProcessFromJson(json);

  Map<String, dynamic> toJson() => _$ServerProcessToJson(this);

  @override
  List<Object?> get props => [cpuUsage, memoryUsage, name, pid];
}
