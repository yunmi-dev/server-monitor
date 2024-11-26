// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ResourceUsageImpl _$$ResourceUsageImplFromJson(Map<String, dynamic> json) =>
    _$ResourceUsageImpl(
      cpu: (json['cpu'] as num).toDouble(),
      memory: (json['memory'] as num).toDouble(),
      disk: (json['disk'] as num).toDouble(),
      network: json['network'] as String,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => TimeSeriesData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'history': instance.history,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
