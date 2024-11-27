// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) => LogEntry(
      id: json['id'] as String,
      level: $enumDecode(_$LogLevelEnumMap, json['level']),
      component: json['component'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String,
      serverId: json['serverId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      stackTrace: json['stackTrace'] as String?,
      userId: json['userId'] as String?,
      tags: (json['tags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$LogEntryToJson(LogEntry instance) => <String, dynamic>{
      'id': instance.id,
      'level': _$LogLevelEnumMap[instance.level]!,
      'component': instance.component,
      'message': instance.message,
      'source': instance.source,
      'timestamp': LogEntry._dateToIso8601String(instance.timestamp),
      'serverId': instance.serverId,
      'metadata': instance.metadata,
      'stackTrace': instance.stackTrace,
      'userId': instance.userId,
      'tags': instance.tags,
    };

const _$LogLevelEnumMap = {
  LogLevel.info: 'info',
  LogLevel.warning: 'warning',
  LogLevel.error: 'error',
  LogLevel.critical: 'critical',
};
