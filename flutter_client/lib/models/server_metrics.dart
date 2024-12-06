// lib/models/server_metrics.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_metrics.freezed.dart';
part 'server_metrics.g.dart';

@freezed
class ServerMetrics with _$ServerMetrics {
  factory ServerMetrics({
    required String serverId,
    @Default('Unknown') String serverName,
    required double cpuUsage,
    required double memoryUsage,
    required double diskUsage,
    required double networkUsage,
    @Default(0) int processCount,
    required DateTime timestamp,
    @Default([]) List<ProcessInfo> processes,
  }) = _ServerMetrics;

  factory ServerMetrics.fromJson(Map<String, dynamic> json) =>
      _$ServerMetricsFromJson(json);
}

@freezed
class ProcessInfo with _$ProcessInfo {
  factory ProcessInfo({
    @JsonKey(defaultValue: 0) required int pid,
    @JsonKey(defaultValue: 'unknown') required String name,
    @JsonKey(defaultValue: 0.0) required double cpuUsage,
    @JsonKey(defaultValue: 0.0) required double memoryUsage,
  }) = _ProcessInfo;

  factory ProcessInfo.fromJson(Map<String, dynamic> json) =>
      _$ProcessInfoFromJson(json);
}
