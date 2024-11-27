// lib/models/log_entry.dart
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'log_entry.g.dart';

@immutable
enum LogLevel {
  @JsonValue('info')
  info('정보'),

  @JsonValue('warning')
  warning('경고'),

  @JsonValue('error')
  error('오류'),

  @JsonValue('critical')
  critical('심각');

  final String label;
  const LogLevel(this.label);

  String get value => _$LogLevelEnumMap[this]!;

  IconData get icon {
    switch (this) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_outlined;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.critical:
        return Icons.dangerous_outlined;
    }
  }

  Color get color {
    switch (this) {
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}

@immutable
@JsonSerializable()
class LogEntry extends Equatable {
  final String id;
  final LogLevel level;
  final String component;
  final String message;
  final String source;
  @JsonKey(fromJson: DateTime.parse, toJson: _dateToIso8601String)
  final DateTime timestamp;
  final String? serverId;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;
  final String? userId;
  final Map<String, String>? tags;

  const LogEntry({
    required this.id,
    required this.level,
    required this.component,
    required this.message,
    required this.timestamp,
    required this.source,
    this.serverId,
    this.metadata,
    this.stackTrace,
    this.userId,
    this.tags,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      _$LogEntryFromJson(json);

  factory LogEntry.now({
    required String id,
    required LogLevel level,
    required String component,
    required String message,
    required String source,
    String? serverId,
    Map<String, dynamic>? metadata,
    String? stackTrace,
    String? userId,
    Map<String, String>? tags,
  }) {
    return LogEntry(
      id: id,
      level: level,
      component: component,
      message: message,
      timestamp: DateTime.now(),
      source: source,
      serverId: serverId,
      metadata: metadata,
      stackTrace: stackTrace,
      userId: userId,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => _$LogEntryToJson(this);

  LogEntry copyWith({
    String? id,
    LogLevel? level,
    String? component,
    String? message,
    DateTime? timestamp,
    String? source,
    String? serverId,
    Map<String, dynamic>? metadata,
    String? stackTrace,
    String? userId,
    Map<String, String>? tags,
  }) {
    return LogEntry(
      id: id ?? this.id,
      level: level ?? this.level,
      component: component ?? this.component,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      serverId: serverId ?? this.serverId,
      metadata: metadata ?? this.metadata,
      stackTrace: stackTrace ?? this.stackTrace,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
    );
  }

  bool get isError => level == LogLevel.error || level == LogLevel.critical;
  bool get isWarning => level == LogLevel.warning;
  bool get isCritical => level == LogLevel.critical;
  bool get needsAttention => isError || isWarning;

  String get formattedMessage => '[$component] $message';

  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  String get exactTimestamp => '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        id,
        level,
        component,
        message,
        timestamp,
        source,
        serverId,
        metadata,
        stackTrace,
        userId,
        tags,
      ];

  @override
  String toString() => 'LogEntry('
      'id: $id, '
      'level: ${level.name}, '
      'component: $component, '
      'message: $message, '
      'timestamp: ${timestamp.toIso8601String()}, '
      'source: $source, '
      'serverId: $serverId, '
      'metadata: $metadata, '
      'stackTrace: $stackTrace, '
      'userId: $userId, '
      'tags: $tags)';

  static String _dateToIso8601String(DateTime date) => date.toIso8601String();
}
