// lib/models/alert.dart
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'alert.g.dart';

@immutable
enum AlertSeverity {
  @JsonValue('info')
  info,

  @JsonValue('warning')
  warning,

  @JsonValue('error')
  error,

  @JsonValue('critical')
  critical;

  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return const Color.fromARGB(255, 113, 191, 255);
      case AlertSeverity.warning:
        return const Color.fromARGB(255, 255, 190, 92);
      case AlertSeverity.error:
        return const Color.fromARGB(255, 255, 111, 101);
      case AlertSeverity.critical:
        return const Color.fromARGB(255, 237, 134, 255);
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_outlined;
      case AlertSeverity.error:
        return Icons.error_outline;
      case AlertSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  String get label {
    return name.toUpperCase();
  }
}

@immutable
@JsonSerializable()
class Alert extends Equatable {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String serverId;
  final String? serverName;
  final bool isRead;
  final String? category;
  final Map<String, dynamic>? metadata;
  final String? source;
  final List<String>? tags;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final List<AlertAction>? actions;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.serverId,
    this.serverName,
    this.isRead = false,
    this.category,
    this.metadata,
    this.source,
    this.tags,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.actions,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
  Map<String, dynamic> toJson() => _$AlertToJson(this);

  Alert copyWith({
    String? id,
    String? title,
    String? message,
    AlertSeverity? severity,
    DateTime? timestamp,
    String? serverId,
    String? serverName,
    bool? isRead,
    String? category,
    Map<String, dynamic>? metadata,
    String? source,
    List<String>? tags,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? resolvedAt,
    String? resolvedBy,
    List<AlertAction>? actions,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      actions: actions ?? this.actions,
    );
  }

  // Utility getters
  bool get isAcknowledged => acknowledgedAt != null;
  bool get isResolved => resolvedAt != null;
  bool get requiresAction =>
      !isAcknowledged && severity.index >= AlertSeverity.error.index;
  bool get isPending => !isResolved && !isAcknowledged;

  // Status calculation
  AlertStatus get status {
    if (isResolved) return AlertStatus.resolved;
    if (isAcknowledged) return AlertStatus.acknowledged;
    return AlertStatus.pending;
  }

  // Time-based utilities
  String get formattedTimestamp => _formatTimestamp(timestamp);
  String get timeSinceCreation => _getTimeSince(timestamp);
  String? get timeSinceAcknowledged =>
      acknowledgedAt != null ? _getTimeSince(acknowledgedAt!) : null;
  String? get timeSinceResolved =>
      resolvedAt != null ? _getTimeSince(resolvedAt!) : null;

  // Alert grouping helper
  String get groupKey => '${serverId}_${category ?? ''}_$severity';

  static String _formatTimestamp(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String _getTimeSince(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        severity,
        timestamp,
        serverId,
        serverName,
        isRead,
        category,
        metadata,
        source,
        tags,
        acknowledgedAt,
        acknowledgedBy,
        resolvedAt,
        resolvedBy,
        actions,
      ];
}

enum AlertStatus { pending, acknowledged, resolved }

@JsonSerializable()
class AlertAction {
  final String id;
  final String label;
  final String type;
  final Map<String, dynamic>? parameters;

  const AlertAction({
    required this.id,
    required this.label,
    required this.type,
    this.parameters,
  });

  factory AlertAction.fromJson(Map<String, dynamic> json) =>
      _$AlertActionFromJson(json);
  Map<String, dynamic> toJson() => _$AlertActionToJson(this);
}
