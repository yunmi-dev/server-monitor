// lib/providers/distribution_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_client/models/chart_data.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/services/monitoring_service.dart';

/// 로딩 상태를 관리하는 provider
final distributionLoadingProvider = StateProvider<bool>((ref) => false);

/// 차트 데이터를 관리하는 provider
final distributionDataProvider =
    StateNotifierProvider<DistributionDataNotifier, List<DistributionData>>(
  (ref) => DistributionDataNotifier(ref),
);

class DistributionDataNotifier extends StateNotifier<List<DistributionData>> {
  final Ref ref;
  DateTime? _lastUpdate;
  bool get _isStale =>
      _lastUpdate == null ||
      DateTime.now().difference(_lastUpdate!) >
          AppConstants.defaultRefreshInterval;

  final _monitoringService = MonitoringService();

  DistributionDataNotifier(this.ref) : super([]) {
    _initializeData();
  }

  /// 초기 데이터 로드 및 자동 새로고침 설정
  Future<void> _initializeData() async {
    await fetchLatestData();
    _setupAutoRefresh();
  }

  /// 자동 새로고침 설정
  void _setupAutoRefresh() {
    Future.delayed(AppConstants.defaultRefreshInterval).then((_) async {
      if (!mounted) return;
      if (_isStale) {
        await fetchLatestData();
      }
      _setupAutoRefresh();
    });
  }

  /// 최신 데이터 가져오기
  Future<void> fetchLatestData() async {
    if (ref.read(distributionLoadingProvider)) return;

    try {
      ref.read(distributionLoadingProvider.notifier).state = true;

      final newData = await _monitoringService.getDistributionData();

      if (!mounted) return;

      updateData(newData);
      _lastUpdate = DateTime.now();
    } catch (e) {
      if (mounted) {
        throw e; // UI에서 처리할 수 있도록 에러를 전파
      }
    } finally {
      if (mounted) {
        ref.read(distributionLoadingProvider.notifier).state = false;
      }
    }
  }

  /// 데이터 업데이트
  void updateData(List<DistributionData> newData) {
    state = newData;
  }

  /// 단일 데이터 포인트 추가
  void addDataPoint(DistributionData dataPoint) {
    state = [...state, dataPoint];
    // AppConstants에 정의된 최대 데이터 포인트 수를 사용
    if (state.length > AppConstants.maxDataPoints) {
      state = state.sublist(state.length - AppConstants.maxDataPoints);
    }
  }

  /// 테스트용 샘플 데이터 생성
  void generateSampleData() {
    final now = DateTime.now();
    final sampleData = List.generate(
      8,
      (index) {
        final timestamp = now
            .subtract(Duration(minutes: (7 - index) * 15))
            .toString()
            .substring(11, 16);
        return DistributionData(
          timestamp: timestamp,
          values: [
            60 + (index * 2.5 + _getRandomOffset()),
            40 + (index * 1.8 + _getRandomOffset()),
            20 + (index * 1.2 + _getRandomOffset()),
          ],
          categories: const ['CPU', 'Memory', 'Disk'],
        );
      },
    );
    updateData(sampleData);
    _lastUpdate = DateTime.now();
  }

  /// 랜덤 오프셋 생성 (더 자연스러운 샘플 데이터를 위해)
  double _getRandomOffset() {
    return (DateTime.now().millisecond % 10) - 5;
  }

  @override
  void dispose() {
    _lastUpdate = null;
    super.dispose();
  }
}
