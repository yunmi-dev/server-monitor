// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ResourceUsageImpl _$$ResourceUsageImplFromJson(Map<String, dynamic> json) =>
    _$ResourceUsageImpl(
      cpu: (json['cpu'] as num?)?.toDouble() ?? 0.0,
      memory: (json['memory'] as num?)?.toDouble() ?? 0.0,
      disk: (json['disk'] as num?)?.toDouble() ?? 0.0,
      network: json['network'] as String? ?? '0 B/s',
      history: json['history'] == null
          ? const []
          : _historyFromJson(json['history'] as List),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$ResourceUsageImplToJson(_$ResourceUsageImpl instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'memory': instance.memory,
      'disk': instance.disk,
      'network': instance.network,
      'history': _historyToJson(instance.history),
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
