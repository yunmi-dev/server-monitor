// lib/widgets/charts/mini_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/time_series_data.dart';

class MiniChart extends StatelessWidget {
  final List<TimeSeriesData> data;
  final Color color;
  final bool animate;
  final bool showDots;

  const MiniChart({
    super.key,
    required this.data,
    required this.color,
    this.animate = true,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      duration: animate ? AppConstants.chartAnimationDuration : Duration.zero,
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: showDots,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1,
                strokeColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
