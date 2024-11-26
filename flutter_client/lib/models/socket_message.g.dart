// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socket_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocketMessage _$SocketMessageFromJson(Map<String, dynamic> json) =>
    SocketMessage(
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SocketMessageToJson(SocketMessage instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type]!,
      'data': instance.data,
      'timestamp': SocketMessage._dateToIso8601String(instance.timestamp),
    };

const _$MessageTypeEnumMap = {
  MessageType.serverStatus: 'server_status',
  MessageType.resourceMetrics: 'resource_metrics',
  MessageType.alert: 'alert',
  MessageType.processInfo: 'process_info',
  MessageType.logEntry: 'log_entry',
  MessageType.systemInfo: 'system_info',
  MessageType.error: 'error',
  MessageType.ping: 'ping',
  MessageType.pong: 'pong',
};

ResourceMetrics _$ResourceMetricsFromJson(Map<String, dynamic> json) =>
    ResourceMetrics(
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      diskUsage: (json['diskUsage'] as num).toDouble(),
      networkUsage: (json['networkUsage'] as num).toDouble(),
      additionalMetrics:
          (json['additionalMetrics'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
    );

Map<String, dynamic> _$ResourceMetricsToJson(ResourceMetrics instance) =>
    <String, dynamic>{
      'cpuUsage': instance.cpuUsage,
      'memoryUsage': instance.memoryUsage,
      'diskUsage': instance.diskUsage,
      'networkUsage': instance.networkUsage,
      'additionalMetrics': instance.additionalMetrics,
    };

ProcessInfo _$ProcessInfoFromJson(Map<String, dynamic> json) => ProcessInfo(
      name: json['name'] as String,
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      threads: (json['threads'] as num).toInt(),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$ProcessInfoToJson(ProcessInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'cpuUsage': instance.cpuUsage,
      'memoryUsage': instance.memoryUsage,
      'threads': instance.threads,
      'status': instance.status,
    };
