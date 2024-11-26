// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServerMetricsImpl _$$ServerMetricsImplFromJson(Map<String, dynamic> json) =>
    _$ServerMetricsImpl(
      serverId: json['serverId'] as String,
      serverName: json['serverName'] as String,
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      diskUsage: (json['diskUsage'] as num).toDouble(),
      networkUsage: (json['networkUsage'] as num).toDouble(),
      processCount: (json['processCount'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
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
    };
