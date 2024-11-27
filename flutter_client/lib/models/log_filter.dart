// lib/models/log_filter.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_client/models/log_entry.dart';

part 'log_filter.freezed.dart';
part 'log_filter.g.dart';

@freezed
class LogFilter with _$LogFilter {
  const factory LogFilter({
    List<LogLevel>? levels,
    DateTime? from,
    DateTime? to,
    String? serverId,
    String? component,
    String? search,
    @Default(50) int limit,
    @Default(0) int offset,
  }) = _LogFilter;

  factory LogFilter.fromJson(Map<String, dynamic> json) =>
      _$LogFilterFromJson(json);
}
