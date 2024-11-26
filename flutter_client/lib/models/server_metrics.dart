// lib/models/server_metrics.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_metrics.freezed.dart';
part 'server_metrics.g.dart';

@freezed
class ServerMetrics with _$ServerMetrics {
  const factory ServerMetrics({
    required String serverId,
    required String serverName,
    required double cpuUsage,
    required double memoryUsage,
    required double diskUsage,
    required double networkUsage,
    required int processCount,
    required DateTime timestamp,
  }) = _ServerMetrics;

  factory ServerMetrics.fromJson(Map<String, dynamic> json) =>
      _$ServerMetricsFromJson(json);
}
