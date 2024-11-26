// lib/models/time_series_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_series_data.freezed.dart';
part 'time_series_data.g.dart';

@freezed
class TimeSeriesData with _$TimeSeriesData {
  const factory TimeSeriesData({
    required DateTime timestamp,
    required double value,
    String? label,
    Map<String, dynamic>? metadata,
  }) = _TimeSeriesData;

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) =>
      _$TimeSeriesDataFromJson(json);

  factory TimeSeriesData.now(double value) => TimeSeriesData(
        timestamp: DateTime.now(),
        value: value,
      );
}
