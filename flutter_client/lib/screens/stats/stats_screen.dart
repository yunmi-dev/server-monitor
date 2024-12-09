// lib/screens/stats/stats_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/widgets/charts/animated_progress_ring.dart';
import 'package:flutter_client/services/websocket_service.dart';
import 'package:flutter_client/widgets/charts/mini_chart.dart';
import 'package:flutter_client/utils/number_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDataSubscription();
    });
  }

  void _setupDataSubscription() {
    // WebSocket 서비스 초기화 및 연결
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    final serverProvider = Provider.of<ServerProvider>(context, listen: false);

    wsService.connect(); // WebSocket 연결

    // 메트릭스 데이터 구독
    _metricsSubscription = wsService.metricsStream.listen((metricsData) {
      if (mounted) {
        serverProvider.handleMetricsUpdate(metricsData);
      }
    });

    // 백업용 폴링 타이머 설정 (WebSocket 연결 실패 시 대비)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !wsService.isConnected) {
        _loadData();
      }
    });

    // 초기 데이터 로드
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ServerProvider>(context, listen: false);
    await provider.refreshResourceUsage();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _metricsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
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
        return Colors.blue;
      case 'memory':
        return Colors.green;
      case 'network':
        return Colors.purple;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.pink,
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            );
          }

          if (provider.servers.isEmpty) {
            return const Center(
              child: Text(
                'No servers connected',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.pink,
            backgroundColor: Colors.black,
            onRefresh: () => provider.refreshResourceUsage(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResourceTab(provider, 'cpu'),
                _buildResourceTab(provider, 'memory'),
                _buildResourceTab(provider, 'network'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourceTab(ServerProvider provider, String type) {
    final color = _getColorForType(type);
    final currentValues = provider.servers.map((server) {
      final history = provider.getServerResourceHistory(server.id, type);
      return history.isNotEmpty ? history.last.value : 0.0;
    }).toList();

    final averageValue = currentValues.isNotEmpty
        ? currentValues.reduce((a, b) => a + b) / currentValues.length
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedProgressRing(
              progress: averageValue / 100,
              label: 'Average ${type.toUpperCase()} Usage',
              color: color,
              icon: _getIconForType(type),
              size: 160,
            ),
          ),
          const SizedBox(height: 24),
          ...provider.servers.map((server) {
            final timeSeriesData =
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
                              timeSeriesData.isNotEmpty
                                  ? timeSeriesData.last.value
                                  : 0.0),
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
                        data: timeSeriesData,
                        color: color,
                        animate: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
