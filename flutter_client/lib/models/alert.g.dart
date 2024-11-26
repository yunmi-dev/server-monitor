// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Alert _$AlertFromJson(Map<String, dynamic> json) => Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: $enumDecode(_$AlertSeverityEnumMap, json['severity']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      serverId: json['serverId'] as String,
      serverName: json['serverName'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      source: json['source'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
      acknowledgedBy: json['acknowledgedBy'] as String?,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      resolvedBy: json['resolvedBy'] as String?,
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => AlertAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AlertToJson(Alert instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'severity': _$AlertSeverityEnumMap[instance.severity]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'serverId': instance.serverId,
      'serverName': instance.serverName,
      'isRead': instance.isRead,
      'category': instance.category,
      'metadata': instance.metadata,
      'source': instance.source,
      'tags': instance.tags,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
      'acknowledgedBy': instance.acknowledgedBy,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'resolvedBy': instance.resolvedBy,
      'actions': instance.actions,
    };

const _$AlertSeverityEnumMap = {
  AlertSeverity.info: 'info',
  AlertSeverity.warning: 'warning',
  AlertSeverity.error: 'error',
  AlertSeverity.critical: 'critical',
};

AlertAction _$AlertActionFromJson(Map<String, dynamic> json) => AlertAction(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AlertActionToJson(AlertAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'type': instance.type,
      'parameters': instance.parameters,
    };
