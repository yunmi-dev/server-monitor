// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimeSeriesDataImpl _$$TimeSeriesDataImplFromJson(Map<String, dynamic> json) =>
    _$TimeSeriesDataImpl(
      timestamp: _dateTimeFromJson(json['timestamp'] as String),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TimeSeriesDataImplToJson(
        _$TimeSeriesDataImpl instance) =>
    <String, dynamic>{
      'timestamp': _dateTimeToJson(instance.timestamp),
      'value': instance.value,
      'label': instance.label,
      'metadata': instance.metadata,
    };
