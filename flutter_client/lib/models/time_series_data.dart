// lib/models/time_series_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_series_data.freezed.dart';
part 'time_series_data.g.dart';

String _dateTimeToJson(DateTime time) => time.toIso8601String();
DateTime _dateTimeFromJson(String time) => DateTime.parse(time);

@freezed
class TimeSeriesData with _$TimeSeriesData {
  @JsonSerializable(explicitToJson: true)
  const factory TimeSeriesData({
    @JsonKey(toJson: _dateTimeToJson, fromJson: _dateTimeFromJson)
    required DateTime timestamp,
    @Default(0.0) double value,
    String? label,
    Map<String, dynamic>? metadata,
  }) = _TimeSeriesData;

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) =>
      _$TimeSeriesDataFromJson(json);

  factory TimeSeriesData.now(double value) => TimeSeriesData(
        timestamp: DateTime.now(),
        value: value,
      );

  factory TimeSeriesData.fromNetworkValue(
      String networkValue, DateTime timestamp) {
    final numValue =
        double.tryParse(networkValue.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    return TimeSeriesData(
      timestamp: timestamp,
      value: numValue,
      metadata: {'unit': networkValue.replaceAll(RegExp(r'[0-9.]'), '').trim()},
    );
  }
}
