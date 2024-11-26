// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimeSeriesDataImpl _$$TimeSeriesDataImplFromJson(Map<String, dynamic> json) =>
    _$TimeSeriesDataImpl(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      label: json['label'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TimeSeriesDataImplToJson(
        _$TimeSeriesDataImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'value': instance.value,
      'label': instance.label,
      'metadata': instance.metadata,
    };
