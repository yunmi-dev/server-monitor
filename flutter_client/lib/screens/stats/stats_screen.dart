// lib/screens/stats/stats_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/widgets/charts/animated_progress_ring.dart';
import 'package:flutter_client/widgets/charts/mini_chart.dart';
import 'package:flutter_client/utils/number_utils.dart';
import 'package:flutter_client/widgets/charts/usage_chart.dart';
import 'package:flutter_client/models/usage_data.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  StreamSubscription? _metricsSubscription;

  final GlobalKey<AnimatedProgressRingState> _progressRingKey =
      GlobalKey<AnimatedProgressRingState>();
  final Map<String, GlobalKey<MiniChartState>> _chartKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<ServerProvider>(context, listen: false);
    await provider.loadServers();
    _setupPollingFallback(provider);
  }

  void _setupPollingFallback(ServerProvider provider) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        if (!mounted) return;
        await provider.refreshResourceUsage();
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _metricsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _getMetricType() {
    switch (_tabController.index) {
      case 0:
        return 'cpu';
      case 1:
        return 'memory';
      case 2:
        return 'network';
      default:
        return 'cpu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF06292),
          labelColor: const Color(0xFFF06292),
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'CPU'),
            Tab(text: 'Memory'),
            Tab(text: 'Network'),
          ],
        ),
      ),
      body: Consumer<ServerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF06292)),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFF06292),
            backgroundColor: Colors.black,
            onRefresh: () async {
              await provider.refreshResourceUsage();
            },
            child: _buildContent(provider),
          );
        },
      ),
    );
  }

  Widget _buildContent(ServerProvider provider) {
    if (provider.servers.isEmpty) {
      return const Center(
        child: Text('No servers connected',
            style: TextStyle(color: Colors.white70)),
      );
    }

    _getMetricType();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildResourceTab(provider, 'cpu'),
        _buildResourceTab(provider, 'memory'),
        _buildResourceTab(provider, 'network'),
      ],
    );
  }

  Widget _buildResourceTab(ServerProvider provider, String type) {
    final color = _getColorForType(type);

    // 모든 서버의 평균값 계산
    final List<UsageData> combinedData =
        provider.convertToUsageData(provider.getCombinedResourceHistory(type));

    // 현재 평균값 계산
    double averageValue = 0;
    switch (type) {
      case 'cpu':
        averageValue = provider.getAverageCpuUsage();
        break;
      case 'memory':
        averageValue = provider.getAverageMemoryUsage();
        break;
      case 'network':
        averageValue = provider.servers.fold(0.0, (sum, server) {
              final value =
                  NumberUtils.parseNetworkValue(server.resources.network);
              return sum + value;
            }) /
            provider.servers.length;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AnimatedProgressRing(
                  key: _progressRingKey,
                  progress: type == 'network'
                      ? min(averageValue / 1000, 1.0)
                      : averageValue / 100,
                  label: type == 'network'
                      ? 'Average ${NumberUtils.formatBandwidth(averageValue)}'
                      : 'Average ${type.toUpperCase()}',
                  color: color,
                  icon: _getIconForType(type),
                  size: 160,
                ),
              ),
              const SizedBox(height: 24),
              // 전체 사용량 추세 차트
              UsageChart(
                title: '${type.toUpperCase()} Usage Trend',
                data: combinedData,
                metrics: const ['Average'],
                colors: [color],
                showLegend: false,
                animate: true,
                onRefresh: () async {
                  await provider.refreshResourceUsage();
                },
              ),
              const SizedBox(height: 24),
              // 개별 서버 차트들
              ...provider.servers.map((server) {
                final history =
                    provider.getServerResourceHistory(server.id, type);

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              server.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatValue(
                                  type,
                                  server.resources.valueForType(type) ??
                                      0.0), // null 체크
                              style: TextStyle(
                                color: color,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: MiniChart(
                            key: _chartKeys[server.id],
                            data: history, // TimeSeriesData 리스트를 직접 전달
                            color: color,
                            animate: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'cpu':
        return Icons.memory;
      case 'memory':
        return Icons.storage;
      case 'network':
        return Icons.network_check;
      default:
        return Icons.error;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'cpu':
        return const Color.fromARGB(255, 113, 191, 255);
      case 'memory':
        return const Color.fromARGB(255, 128, 217, 131);
      case 'network':
        return const Color.fromARGB(255, 237, 134, 255);
      default:
        return Colors.grey;
    }
  }

  String _formatValue(String type, double value) {
    if (type == 'network') {
      return NumberUtils.formatBandwidth(value);
    }
    return '${value.toStringAsFixed(1)}%';
  }
}
