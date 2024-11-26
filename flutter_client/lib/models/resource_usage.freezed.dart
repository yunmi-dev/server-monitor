// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_usage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ResourceUsage _$ResourceUsageFromJson(Map<String, dynamic> json) {
  return _ResourceUsage.fromJson(json);
}

/// @nodoc
mixin _$ResourceUsage {
  double get cpu => throw _privateConstructorUsedError; // percentage
  double get memory => throw _privateConstructorUsedError; // percentage
  double get disk => throw _privateConstructorUsedError; // percentage
  String get network =>
      throw _privateConstructorUsedError; // formatted string (e.g., "1.2 MB/s")
  List<TimeSeriesData> get history => throw _privateConstructorUsedError;
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this ResourceUsage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResourceUsage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResourceUsageCopyWith<ResourceUsage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResourceUsageCopyWith<$Res> {
  factory $ResourceUsageCopyWith(
          ResourceUsage value, $Res Function(ResourceUsage) then) =
      _$ResourceUsageCopyWithImpl<$Res, ResourceUsage>;
  @useResult
  $Res call(
      {double cpu,
      double memory,
      double disk,
      String network,
      List<TimeSeriesData> history,
      DateTime? lastUpdated});
}

/// @nodoc
class _$ResourceUsageCopyWithImpl<$Res, $Val extends ResourceUsage>
    implements $ResourceUsageCopyWith<$Res> {
  _$ResourceUsageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResourceUsage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpu = null,
    Object? memory = null,
    Object? disk = null,
    Object? network = null,
    Object? history = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      cpu: null == cpu
          ? _value.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as double,
      memory: null == memory
          ? _value.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as double,
      disk: null == disk
          ? _value.disk
          : disk // ignore: cast_nullable_to_non_nullable
              as double,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      history: null == history
          ? _value.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<TimeSeriesData>,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ResourceUsageImplCopyWith<$Res>
    implements $ResourceUsageCopyWith<$Res> {
  factory _$$ResourceUsageImplCopyWith(
          _$ResourceUsageImpl value, $Res Function(_$ResourceUsageImpl) then) =
      __$$ResourceUsageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double cpu,
      double memory,
      double disk,
      String network,
      List<TimeSeriesData> history,
      DateTime? lastUpdated});
}

/// @nodoc
class __$$ResourceUsageImplCopyWithImpl<$Res>
    extends _$ResourceUsageCopyWithImpl<$Res, _$ResourceUsageImpl>
    implements _$$ResourceUsageImplCopyWith<$Res> {
  __$$ResourceUsageImplCopyWithImpl(
      _$ResourceUsageImpl _value, $Res Function(_$ResourceUsageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ResourceUsage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpu = null,
    Object? memory = null,
    Object? disk = null,
    Object? network = null,
    Object? history = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$ResourceUsageImpl(
      cpu: null == cpu
          ? _value.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as double,
      memory: null == memory
          ? _value.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as double,
      disk: null == disk
          ? _value.disk
          : disk // ignore: cast_nullable_to_non_nullable
              as double,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as String,
      history: null == history
          ? _value._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<TimeSeriesData>,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ResourceUsageImpl extends _ResourceUsage {
  const _$ResourceUsageImpl(
      {required this.cpu,
      required this.memory,
      required this.disk,
      required this.network,
      final List<TimeSeriesData> history = const [],
      this.lastUpdated})
      : _history = history,
        super._();

  factory _$ResourceUsageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResourceUsageImplFromJson(json);

  @override
  final double cpu;
// percentage
  @override
  final double memory;
// percentage
  @override
  final double disk;
// percentage
  @override
  final String network;
// formatted string (e.g., "1.2 MB/s")
  final List<TimeSeriesData> _history;
// formatted string (e.g., "1.2 MB/s")
  @override
  @JsonKey()
  List<TimeSeriesData> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'ResourceUsage(cpu: $cpu, memory: $memory, disk: $disk, network: $network, history: $history, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResourceUsageImpl &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            (identical(other.memory, memory) || other.memory == memory) &&
            (identical(other.disk, disk) || other.disk == disk) &&
            (identical(other.network, network) || other.network == network) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cpu, memory, disk, network,
      const DeepCollectionEquality().hash(_history), lastUpdated);

  /// Create a copy of ResourceUsage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResourceUsageImplCopyWith<_$ResourceUsageImpl> get copyWith =>
      __$$ResourceUsageImplCopyWithImpl<_$ResourceUsageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ResourceUsageImplToJson(
      this,
    );
  }
}

abstract class _ResourceUsage extends ResourceUsage {
  const factory _ResourceUsage(
      {required final double cpu,
      required final double memory,
      required final double disk,
      required final String network,
      final List<TimeSeriesData> history,
      final DateTime? lastUpdated}) = _$ResourceUsageImpl;
  const _ResourceUsage._() : super._();

  factory _ResourceUsage.fromJson(Map<String, dynamic> json) =
      _$ResourceUsageImpl.fromJson;

  @override
  double get cpu; // percentage
  @override
  double get memory; // percentage
  @override
  double get disk; // percentage
  @override
  String get network; // formatted string (e.g., "1.2 MB/s")
  @override
  List<TimeSeriesData> get history;
  @override
  DateTime? get lastUpdated;

  /// Create a copy of ResourceUsage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResourceUsageImplCopyWith<_$ResourceUsageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
