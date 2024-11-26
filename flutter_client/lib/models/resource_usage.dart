// lib/models/resource_usage.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_client/models/time_series_data.dart';

part 'resource_usage.freezed.dart';
part 'resource_usage.g.dart';

@freezed
class ResourceUsage with _$ResourceUsage {
  const ResourceUsage._(); // Custom getters를 위한 private constructor

  const factory ResourceUsage({
    required double cpu, // percentage
    required double memory, // percentage
    required double disk, // percentage
    required String network, // formatted string (e.g., "1.2 MB/s")
    @Default([]) List<TimeSeriesData> history,
    DateTime? lastUpdated,
  }) = _ResourceUsage;

  factory ResourceUsage.fromJson(Map<String, dynamic> json) =>
      _$ResourceUsageFromJson(json);

  /// CPU 사용량이 경고 수준인지 확인
  bool get isCpuWarning => cpu >= 80;

  /// 메모리 사용량이 경고 수준인지 확인
  bool get isMemoryWarning => memory >= 80;

  /// 디스크 사용량이 경고 수준인지 확인
  bool get isDiskWarning => disk >= 90;

  /// 전체적으로 경고 상태인지 확인
  bool get hasWarning => isCpuWarning || isMemoryWarning || isDiskWarning;

  /// CPU 사용량 히스토리
  List<TimeSeriesData> get cpuHistory =>
      history.where((data) => data.metadata?['type'] == 'cpu').toList();

  /// 메모리 사용량 히스토리
  List<TimeSeriesData> get memoryHistory =>
      history.where((data) => data.metadata?['type'] == 'memory').toList();

  /// 디스크 사용량 히스토리
  List<TimeSeriesData> get diskHistory =>
      history.where((data) => data.metadata?['type'] == 'disk').toList();

  /// 네트워크 사용량 히스토리
  List<TimeSeriesData> get networkHistory =>
      history.where((data) => data.metadata?['type'] == 'network').toList();

  /// 마지막 업데이트로부터의 경과 시간
  Duration get timeSinceLastUpdate =>
      DateTime.now().difference(lastUpdated ?? DateTime.now());

  /// 새로운 데이터 포인트 추가
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

  /// 지정된 기간의 데이터만 유지
  ResourceUsage trimHistory(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return copyWith(
      history: history.where((data) => data.timestamp.isAfter(cutoff)).toList(),
    );
  }

  /// 빈 리소스 사용량 객체 생성
  factory ResourceUsage.empty() => const ResourceUsage(
        cpu: 0,
        memory: 0,
        disk: 0,
        network: '0 B/s',
      );
}
