// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServerMetricsImpl _$$ServerMetricsImplFromJson(Map<String, dynamic> json) =>
    _$ServerMetricsImpl(
      serverId: json['serverId'] as String,
      serverName: json['serverName'] as String? ?? 'Unknown',
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      diskUsage: (json['diskUsage'] as num).toDouble(),
      networkUsage: (json['networkUsage'] as num).toDouble(),
      processCount: (json['processCount'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      processes: (json['processes'] as List<dynamic>?)
              ?.map((e) => ProcessInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ServerMetricsImplToJson(_$ServerMetricsImpl instance) =>
    <String, dynamic>{
      'serverId': instance.serverId,
      'serverName': instance.serverName,
      'cpuUsage': instance.cpuUsage,
      'memoryUsage': instance.memoryUsage,
      'diskUsage': instance.diskUsage,
      'networkUsage': instance.networkUsage,
      'processCount': instance.processCount,
      'timestamp': instance.timestamp.toIso8601String(),
      'processes': instance.processes,
    };

_$ProcessInfoImpl _$$ProcessInfoImplFromJson(Map<String, dynamic> json) =>
    _$ProcessInfoImpl(
      pid: (json['pid'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'unknown',
      cpuUsage: (json['cpuUsage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (json['memoryUsage'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$ProcessInfoImplToJson(_$ProcessInfoImpl instance) =>
    <String, dynamic>{
      'pid': instance.pid,
      'name': instance.name,
      'cpuUsage': instance.cpuUsage,
      'memoryUsage': instance.memoryUsage,
    };
