// lib/screens/stats/stats_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/utils/date_utils.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupDataRefresh();
  }

  void _setupDataRefresh() {
    // 초기 데이터 로드
    _loadData();

    // 주기적 새로고침 설정 (5초 간격)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ServerProvider>(context, listen: false);
    await provider.refreshResourceUsage();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
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
          if (provider.isLoading && provider.servers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildResourceTab(provider, 'cpu', Colors.blue),
              _buildResourceTab(provider, 'memory', Colors.green),
              _buildResourceTab(provider, 'network', Colors.purple),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResourceTab(ServerProvider provider, String type, Color color) {
    final data = provider.getCombinedResourceHistory(type);

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 최근 30개의 데이터 포인트만 사용
    final recentData = data.length > 30 ? data.sublist(data.length - 30) : data;

    final values = recentData.map((d) => d.value).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final avgValue = values.reduce((a, b) => a + b) / values.length;

    String formatValue(double value) {
      if (type == 'network') {
        return NumberUtils.formatBandwidth(value);
      }
      return '${value.toStringAsFixed(1)}%';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSummary(
            maxValue: maxValue,
            minValue: minValue,
            avgValue: avgValue,
            formatValue: formatValue,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= recentData.length)
                          return const Text('');
                        return Text(
                          DateTimeUtils.formatShortTime(
                            recentData[value.toInt()].timestamp,
                          ),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      interval: recentData.length / 5,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          formatValue(value),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      interval: maxValue / 5,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (recentData.length - 1).toDouble(),
                minY: 0,
                maxY: maxValue * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: recentData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.value,
                      );
                    }).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary({
    required double maxValue,
    required double minValue,
    required double avgValue,
    required String Function(double) formatValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Max', maxValue, formatValue, Colors.red),
        _buildStatItem('Avg', avgValue, formatValue, Colors.yellow),
        _buildStatItem('Min', minValue, formatValue, Colors.green),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    double value,
    String Function(double) formatValue,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatValue(value),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
