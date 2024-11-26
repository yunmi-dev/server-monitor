// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiResponseImpl _$$ApiResponseImplFromJson(Map<String, dynamic> json) =>
    _$ApiResponseImpl(
      success: json['success'] as bool,
      message: json['message'] as String?,
      code: json['code'] as String?,
      data: json['data'],
      meta: json['meta'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ApiResponseImplToJson(_$ApiResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      if (instance.message case final value?) 'message': value,
      if (instance.code case final value?) 'code': value,
      if (instance.data case final value?) 'data': value,
      'meta': instance.meta,
    };
