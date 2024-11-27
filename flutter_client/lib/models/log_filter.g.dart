// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LogFilterImpl _$$LogFilterImplFromJson(Map<String, dynamic> json) =>
    _$LogFilterImpl(
      levels: (json['levels'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$LogLevelEnumMap, e))
          .toList(),
      from:
          json['from'] == null ? null : DateTime.parse(json['from'] as String),
      to: json['to'] == null ? null : DateTime.parse(json['to'] as String),
      serverId: json['serverId'] as String?,
      component: json['component'] as String?,
      search: json['search'] as String?,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$LogFilterImplToJson(_$LogFilterImpl instance) =>
    <String, dynamic>{
      'levels': instance.levels?.map((e) => _$LogLevelEnumMap[e]!).toList(),
      'from': instance.from?.toIso8601String(),
      'to': instance.to?.toIso8601String(),
      'serverId': instance.serverId,
      'component': instance.component,
      'search': instance.search,
      'limit': instance.limit,
      'offset': instance.offset,
    };

const _$LogLevelEnumMap = {
  LogLevel.info: 'info',
  LogLevel.warning: 'warning',
  LogLevel.error: 'error',
  LogLevel.critical: 'critical',
};
