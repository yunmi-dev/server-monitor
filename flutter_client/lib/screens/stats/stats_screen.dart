// lib/screens/stats/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/utils/date_utils.dart';
import 'package:flutter_client/utils/number_utils.dart';
import 'package:flutter_client/models/time_series_data.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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
          tabs: const [
            Tab(text: 'CPU'),
            Tab(text: 'Memory'),
            Tab(text: 'Network'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCpuStats(),
          _buildMemoryStats(),
          _buildNetworkStats(),
        ],
      ),
    );
  }

  Widget _buildCpuStats() {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        final cpuData = provider.getCombinedResourceHistory('cpu');
        return _buildStatsSection(
          title: 'CPU Usage',
          data: cpuData,
          color: Colors.blue,
          formatValue: (value) => '${value.toStringAsFixed(1)}%',
        );
      },
    );
  }

  Widget _buildMemoryStats() {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        final memoryData = provider.getCombinedResourceHistory('memory');
        return _buildStatsSection(
          title: 'Memory Usage',
          data: memoryData,
          color: Colors.green,
          formatValue: (value) => '${value.toStringAsFixed(1)}%',
        );
      },
    );
  }

  Widget _buildNetworkStats() {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        final networkData = provider.getCombinedResourceHistory('network');
        return _buildStatsSection(
          title: 'Network Traffic',
          data: networkData,
          color: Colors.purple,
          formatValue: (value) => NumberUtils.formatBandwidth(value),
        );
      },
    );
  }

  Widget _buildStatsSection({
    required String title,
    required List<TimeSeriesData> data,
    required Color color,
    required String Function(double) formatValue,
  }) {
    if (data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final avgValue =
        data.map((e) => e.value).reduce((a, b) => a + b) / data.length;

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
                        if (value.toInt() >= data.length) return const Text('');
                        return Text(
                          DateTimeUtils.formatShortTime(
                              data[value.toInt()].timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      interval: data.length / 5,
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
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: maxValue * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
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
