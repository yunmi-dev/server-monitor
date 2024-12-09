// lib/models/resource_usage.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_client/models/time_series_data.dart';

part 'resource_usage.freezed.dart';
part 'resource_usage.g.dart';

List<Map<String, dynamic>> _historyToJson(List<TimeSeriesData> history) {
  return history.map((data) => data.toJson()).toList();
}

List<TimeSeriesData> _historyFromJson(List<dynamic> jsonList) {
  return jsonList
      .map((json) => TimeSeriesData.fromJson(json as Map<String, dynamic>))
      .toList();
}

@freezed
class ResourceUsage with _$ResourceUsage {
  const ResourceUsage._();

  @JsonSerializable(explicitToJson: true)
  const factory ResourceUsage({
    @JsonKey(defaultValue: 0.0) required double cpu,
    @JsonKey(defaultValue: 0.0) required double memory,
    @JsonKey(defaultValue: 0.0) required double disk,
    @JsonKey(defaultValue: '0 B/s') required String network,
    @JsonKey(toJson: _historyToJson, fromJson: _historyFromJson)
    @Default([])
    List<TimeSeriesData> history,
    DateTime? lastUpdated,
  }) = _ResourceUsage;

  factory ResourceUsage.fromJson(Map<String, dynamic> json) =>
      _$ResourceUsageFromJson(json);

  double get cpuUsage => cpu;
  double get memoryUsage => memory;
  double get diskUsage => disk;
  String get networkUsage => network;

  bool get isCpuWarning => cpu >= 80;
  bool get isMemoryWarning => memory >= 80;
  bool get isDiskWarning => disk >= 90;
  bool get hasWarning => isCpuWarning || isMemoryWarning || isDiskWarning;

  List<TimeSeriesData> get cpuHistory =>
      history.where((data) => data.metadata?['type'] == 'cpu').toList();

  List<TimeSeriesData> get memoryHistory =>
      history.where((data) => data.metadata?['type'] == 'memory').toList();

  List<TimeSeriesData> get diskHistory =>
      history.where((data) => data.metadata?['type'] == 'disk').toList();

  List<TimeSeriesData> get networkHistory =>
      history.where((data) => data.metadata?['type'] == 'network').toList();

  Duration get timeSinceLastUpdate =>
      DateTime.now().difference(lastUpdated ?? DateTime.now());

  ResourceUsage addDataPoint({
    double? cpuValue,
    double? memoryValue,
    double? diskValue,
    double? networkValue,
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final newHistory = List<TimeSeriesData>.from(history);

    if (cpuValue != null) {
      newHistory.add(TimeSeriesData(
        timestamp: time,
        value: cpuValue,
        metadata: {'type': 'cpu'},
      ));
    }

    if (memoryValue != null) {
      newHistory.add(TimeSeriesData(
        timestamp: time,
        value: memoryValue,
        metadata: {'type': 'memory'},
      ));
    }

    if (diskValue != null) {
      newHistory.add(TimeSeriesData(
        timestamp: time,
        value: diskValue,
        metadata: {'type': 'disk'},
      ));
    }

    if (networkValue != null) {
      newHistory.add(TimeSeriesData(
        timestamp: time,
        value: networkValue,
        metadata: {'type': 'network'},
      ));
    }

    return copyWith(
      history: newHistory,
      lastUpdated: time,
    );
  }

  double valueForType(String type) {
    switch (type) {
      case 'cpu':
        return cpu;
      case 'memory':
        return memory;
      case 'disk':
        return disk;
      case 'network':
        // Convert network string to numeric value if needed
        // This is a simplified example - you might need to parse the network string
        return double.tryParse(network.split(' ').first) ?? 0.0;
      default:
        return 0.0;
    }
  }

  ResourceUsage trimHistory(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return copyWith(
      history: history.where((data) => data.timestamp.isAfter(cutoff)).toList(),
    );
  }

  factory ResourceUsage.empty() => const ResourceUsage(
        cpu: 0,
        memory: 0,
        disk: 0,
        network: '0 B/s',
      );
}
