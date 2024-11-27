// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LogFilter _$LogFilterFromJson(Map<String, dynamic> json) {
  return _LogFilter.fromJson(json);
}

/// @nodoc
mixin _$LogFilter {
  List<LogLevel>? get levels => throw _privateConstructorUsedError;
  DateTime? get from => throw _privateConstructorUsedError;
  DateTime? get to => throw _privateConstructorUsedError;
  String? get serverId => throw _privateConstructorUsedError;
  String? get component => throw _privateConstructorUsedError;
  String? get search => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get offset => throw _privateConstructorUsedError;

  /// Serializes this LogFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LogFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LogFilterCopyWith<LogFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogFilterCopyWith<$Res> {
  factory $LogFilterCopyWith(LogFilter value, $Res Function(LogFilter) then) =
      _$LogFilterCopyWithImpl<$Res, LogFilter>;
  @useResult
  $Res call(
      {List<LogLevel>? levels,
      DateTime? from,
      DateTime? to,
      String? serverId,
      String? component,
      String? search,
      int limit,
      int offset});
}

/// @nodoc
class _$LogFilterCopyWithImpl<$Res, $Val extends LogFilter>
    implements $LogFilterCopyWith<$Res> {
  _$LogFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LogFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? levels = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? serverId = freezed,
    Object? component = freezed,
    Object? search = freezed,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(_value.copyWith(
      levels: freezed == levels
          ? _value.levels
          : levels // ignore: cast_nullable_to_non_nullable
              as List<LogLevel>?,
      from: freezed == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      to: freezed == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      serverId: freezed == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String?,
      component: freezed == component
          ? _value.component
          : component // ignore: cast_nullable_to_non_nullable
              as String?,
      search: freezed == search
          ? _value.search
          : search // ignore: cast_nullable_to_non_nullable
              as String?,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LogFilterImplCopyWith<$Res>
    implements $LogFilterCopyWith<$Res> {
  factory _$$LogFilterImplCopyWith(
          _$LogFilterImpl value, $Res Function(_$LogFilterImpl) then) =
      __$$LogFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<LogLevel>? levels,
      DateTime? from,
      DateTime? to,
      String? serverId,
      String? component,
      String? search,
      int limit,
      int offset});
}

/// @nodoc
class __$$LogFilterImplCopyWithImpl<$Res>
    extends _$LogFilterCopyWithImpl<$Res, _$LogFilterImpl>
    implements _$$LogFilterImplCopyWith<$Res> {
  __$$LogFilterImplCopyWithImpl(
      _$LogFilterImpl _value, $Res Function(_$LogFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? levels = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? serverId = freezed,
    Object? component = freezed,
    Object? search = freezed,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(_$LogFilterImpl(
      levels: freezed == levels
          ? _value._levels
          : levels // ignore: cast_nullable_to_non_nullable
              as List<LogLevel>?,
      from: freezed == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      to: freezed == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      serverId: freezed == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String?,
      component: freezed == component
          ? _value.component
          : component // ignore: cast_nullable_to_non_nullable
              as String?,
      search: freezed == search
          ? _value.search
          : search // ignore: cast_nullable_to_non_nullable
              as String?,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LogFilterImpl implements _LogFilter {
  const _$LogFilterImpl(
      {final List<LogLevel>? levels,
      this.from,
      this.to,
      this.serverId,
      this.component,
      this.search,
      this.limit = 50,
      this.offset = 0})
      : _levels = levels;

  factory _$LogFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogFilterImplFromJson(json);

  final List<LogLevel>? _levels;
  @override
  List<LogLevel>? get levels {
    final value = _levels;
    if (value == null) return null;
    if (_levels is EqualUnmodifiableListView) return _levels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? from;
  @override
  final DateTime? to;
  @override
  final String? serverId;
  @override
  final String? component;
  @override
  final String? search;
  @override
  @JsonKey()
  final int limit;
  @override
  @JsonKey()
  final int offset;

  @override
  String toString() {
    return 'LogFilter(levels: $levels, from: $from, to: $to, serverId: $serverId, component: $component, search: $search, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogFilterImpl &&
            const DeepCollectionEquality().equals(other._levels, _levels) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.component, component) ||
                other.component == component) &&
            (identical(other.search, search) || other.search == search) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_levels),
      from,
      to,
      serverId,
      component,
      search,
      limit,
      offset);

  /// Create a copy of LogFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LogFilterImplCopyWith<_$LogFilterImpl> get copyWith =>
      __$$LogFilterImplCopyWithImpl<_$LogFilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LogFilterImplToJson(
      this,
    );
  }
}

abstract class _LogFilter implements LogFilter {
  const factory _LogFilter(
      {final List<LogLevel>? levels,
      final DateTime? from,
      final DateTime? to,
      final String? serverId,
      final String? component,
      final String? search,
      final int limit,
      final int offset}) = _$LogFilterImpl;

  factory _LogFilter.fromJson(Map<String, dynamic> json) =
      _$LogFilterImpl.fromJson;

  @override
  List<LogLevel>? get levels;
  @override
  DateTime? get from;
  @override
  DateTime? get to;
  @override
  String? get serverId;
  @override
  String? get component;
  @override
  String? get search;
  @override
  int get limit;
  @override
  int get offset;

  /// Create a copy of LogFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogFilterImplCopyWith<_$LogFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
