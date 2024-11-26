// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ServerMetrics _$ServerMetricsFromJson(Map<String, dynamic> json) {
  return _ServerMetrics.fromJson(json);
}

/// @nodoc
mixin _$ServerMetrics {
  String get serverId => throw _privateConstructorUsedError;
  String get serverName => throw _privateConstructorUsedError;
  double get cpuUsage => throw _privateConstructorUsedError;
  double get memoryUsage => throw _privateConstructorUsedError;
  double get diskUsage => throw _privateConstructorUsedError;
  double get networkUsage => throw _privateConstructorUsedError;
  int get processCount => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this ServerMetrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServerMetricsCopyWith<ServerMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServerMetricsCopyWith<$Res> {
  factory $ServerMetricsCopyWith(
          ServerMetrics value, $Res Function(ServerMetrics) then) =
      _$ServerMetricsCopyWithImpl<$Res, ServerMetrics>;
  @useResult
  $Res call(
      {String serverId,
      String serverName,
      double cpuUsage,
      double memoryUsage,
      double diskUsage,
      double networkUsage,
      int processCount,
      DateTime timestamp});
}

/// @nodoc
class _$ServerMetricsCopyWithImpl<$Res, $Val extends ServerMetrics>
    implements $ServerMetricsCopyWith<$Res> {
  _$ServerMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serverId = null,
    Object? serverName = null,
    Object? cpuUsage = null,
    Object? memoryUsage = null,
    Object? diskUsage = null,
    Object? networkUsage = null,
    Object? processCount = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      serverId: null == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String,
      serverName: null == serverName
          ? _value.serverName
          : serverName // ignore: cast_nullable_to_non_nullable
              as String,
      cpuUsage: null == cpuUsage
          ? _value.cpuUsage
          : cpuUsage // ignore: cast_nullable_to_non_nullable
              as double,
      memoryUsage: null == memoryUsage
          ? _value.memoryUsage
          : memoryUsage // ignore: cast_nullable_to_non_nullable
              as double,
      diskUsage: null == diskUsage
          ? _value.diskUsage
          : diskUsage // ignore: cast_nullable_to_non_nullable
              as double,
      networkUsage: null == networkUsage
          ? _value.networkUsage
          : networkUsage // ignore: cast_nullable_to_non_nullable
              as double,
      processCount: null == processCount
          ? _value.processCount
          : processCount // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServerMetricsImplCopyWith<$Res>
    implements $ServerMetricsCopyWith<$Res> {
  factory _$$ServerMetricsImplCopyWith(
          _$ServerMetricsImpl value, $Res Function(_$ServerMetricsImpl) then) =
      __$$ServerMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String serverId,
      String serverName,
      double cpuUsage,
      double memoryUsage,
      double diskUsage,
      double networkUsage,
      int processCount,
      DateTime timestamp});
}

/// @nodoc
class __$$ServerMetricsImplCopyWithImpl<$Res>
    extends _$ServerMetricsCopyWithImpl<$Res, _$ServerMetricsImpl>
    implements _$$ServerMetricsImplCopyWith<$Res> {
  __$$ServerMetricsImplCopyWithImpl(
      _$ServerMetricsImpl _value, $Res Function(_$ServerMetricsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serverId = null,
    Object? serverName = null,
    Object? cpuUsage = null,
    Object? memoryUsage = null,
    Object? diskUsage = null,
    Object? networkUsage = null,
    Object? processCount = null,
    Object? timestamp = null,
  }) {
    return _then(_$ServerMetricsImpl(
      serverId: null == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String,
      serverName: null == serverName
          ? _value.serverName
          : serverName // ignore: cast_nullable_to_non_nullable
              as String,
      cpuUsage: null == cpuUsage
          ? _value.cpuUsage
          : cpuUsage // ignore: cast_nullable_to_non_nullable
              as double,
      memoryUsage: null == memoryUsage
          ? _value.memoryUsage
          : memoryUsage // ignore: cast_nullable_to_non_nullable
              as double,
      diskUsage: null == diskUsage
          ? _value.diskUsage
          : diskUsage // ignore: cast_nullable_to_non_nullable
              as double,
      networkUsage: null == networkUsage
          ? _value.networkUsage
          : networkUsage // ignore: cast_nullable_to_non_nullable
              as double,
      processCount: null == processCount
          ? _value.processCount
          : processCount // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServerMetricsImpl implements _ServerMetrics {
  const _$ServerMetricsImpl(
      {required this.serverId,
      required this.serverName,
      required this.cpuUsage,
      required this.memoryUsage,
      required this.diskUsage,
      required this.networkUsage,
      required this.processCount,
      required this.timestamp});

  factory _$ServerMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServerMetricsImplFromJson(json);

  @override
  final String serverId;
  @override
  final String serverName;
  @override
  final double cpuUsage;
  @override
  final double memoryUsage;
  @override
  final double diskUsage;
  @override
  final double networkUsage;
  @override
  final int processCount;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'ServerMetrics(serverId: $serverId, serverName: $serverName, cpuUsage: $cpuUsage, memoryUsage: $memoryUsage, diskUsage: $diskUsage, networkUsage: $networkUsage, processCount: $processCount, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerMetricsImpl &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.serverName, serverName) ||
                other.serverName == serverName) &&
            (identical(other.cpuUsage, cpuUsage) ||
                other.cpuUsage == cpuUsage) &&
            (identical(other.memoryUsage, memoryUsage) ||
                other.memoryUsage == memoryUsage) &&
            (identical(other.diskUsage, diskUsage) ||
                other.diskUsage == diskUsage) &&
            (identical(other.networkUsage, networkUsage) ||
                other.networkUsage == networkUsage) &&
            (identical(other.processCount, processCount) ||
                other.processCount == processCount) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, serverId, serverName, cpuUsage,
      memoryUsage, diskUsage, networkUsage, processCount, timestamp);

  /// Create a copy of ServerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerMetricsImplCopyWith<_$ServerMetricsImpl> get copyWith =>
      __$$ServerMetricsImplCopyWithImpl<_$ServerMetricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServerMetricsImplToJson(
      this,
    );
  }
}

abstract class _ServerMetrics implements ServerMetrics {
  const factory _ServerMetrics(
      {required final String serverId,
      required final String serverName,
      required final double cpuUsage,
      required final double memoryUsage,
      required final double diskUsage,
      required final double networkUsage,
      required final int processCount,
      required final DateTime timestamp}) = _$ServerMetricsImpl;

  factory _ServerMetrics.fromJson(Map<String, dynamic> json) =
      _$ServerMetricsImpl.fromJson;

  @override
  String get serverId;
  @override
  String get serverName;
  @override
  double get cpuUsage;
  @override
  double get memoryUsage;
  @override
  double get diskUsage;
  @override
  double get networkUsage;
  @override
  int get processCount;
  @override
  DateTime get timestamp;

  /// Create a copy of ServerMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerMetricsImplCopyWith<_$ServerMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
