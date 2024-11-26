import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/usage_data.dart';
import 'package:flutter_client/utils/number_utils.dart';

class UsageChart extends StatelessWidget {
  final List<UsageData> data;
  final List<String> metrics;
  final List<Color>? colors;
  final String? title;
  final bool showLegend;
  final bool animate;
  final bool filled;
  final VoidCallback? onRefresh;

  const UsageChart({
    super.key,
    required this.data,
    required this.metrics,
    this.colors,
    this.title,
    this.showLegend = true,
    this.animate = true,
    this.filled = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];

    final chartColors = colors ?? defaultColors;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                      tooltip: '새로고침',
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacing),
            ],
            SizedBox(
              height: 200,
              child: LineChart(
                duration: animate
                    ? AppConstants.chartAnimationDuration
                    : Duration.zero,
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipMargin: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipRoundedRadius: 8,
                      tooltipBorder: BorderSide(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot spot) {
                          final value = NumberUtils.roundToDecimal(spot.y, 1);
                          return LineTooltipItem(
                            '${metrics[spot.barIndex]}: $value%',
                            TextStyle(
                              color: chartColors[spot.barIndex],
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.surfaceContainerHighest,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.surfaceContainerHighest,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: data.length > 6 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[value.toInt()].timestamp,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${value.toInt()}%',
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                        reservedSize: 42,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: metrics.asMap().entries.map((entry) {
                    final metricIndex = entry.key;
                    return LineChartBarData(
                      spots: data.asMap().entries.map((dataEntry) {
                        return FlSpot(
                          dataEntry.key.toDouble(),
                          dataEntry.value.values[metricIndex],
                        );
                      }).toList(),
                      isCurved: true,
                      color: chartColors[metricIndex],
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: data.length <= 8,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: chartColors[metricIndex],
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: filled,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            chartColors[metricIndex].withOpacity(0.2),
                            chartColors[metricIndex].withOpacity(0.0),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (showLegend) ...[
              const SizedBox(height: AppConstants.spacing),
              _buildLegend(context, chartColors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<Color> chartColors) {
    return Wrap(
      spacing: AppConstants.spacing,
      runSpacing: AppConstants.spacing / 2,
      children: metrics.asMap().entries.map((entry) {
        final index = entry.key;
        final metric = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: chartColors[index],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              metric,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}
