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
  MessageType.log: 'log',
  MessageType.unknown: 'unknown',
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

ServerMetricsData _$ServerMetricsDataFromJson(Map<String, dynamic> json) =>
    ServerMetricsData(
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      diskUsage: (json['diskUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      networkUsage: (json['networkUsage'] as num).toDouble(),
      processCount: (json['processCount'] as num).toInt(),
      processes: (json['processes'] as List<dynamic>)
          .map((e) => ServerProcess.fromJson(e as Map<String, dynamic>))
          .toList(),
      serverId: json['serverId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ServerMetricsDataToJson(ServerMetricsData instance) =>
    <String, dynamic>{
      'cpuUsage': instance.cpuUsage,
      'diskUsage': instance.diskUsage,
      'memoryUsage': instance.memoryUsage,
      'networkUsage': instance.networkUsage,
      'processCount': instance.processCount,
      'processes': instance.processes,
      'serverId': instance.serverId,
      'timestamp': ServerMetricsData._dateToIso8601String(instance.timestamp),
    };

ServerProcess _$ServerProcessFromJson(Map<String, dynamic> json) =>
    ServerProcess(
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toInt(),
      name: json['name'] as String,
      pid: (json['pid'] as num).toInt(),
    );

Map<String, dynamic> _$ServerProcessToJson(ServerProcess instance) =>
    <String, dynamic>{
      'cpuUsage': instance.cpuUsage,
      'memoryUsage': instance.memoryUsage,
      'name': instance.name,
      'pid': instance.pid,
    };
