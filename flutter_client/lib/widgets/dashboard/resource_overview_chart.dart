// lib/widgets/dashboard/resource_overview_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ResourceOverviewChart extends StatelessWidget {
  const ResourceOverviewChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resource Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}:00',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _createLineBarsData(
                      context,
                      [40, 35, 45, 38, 42, 39, 41],
                      Colors.blue,
                      'CPU',
                    ),
                    _createLineBarsData(
                      context,
                      [65, 62, 68, 63, 66, 64, 65],
                      Colors.green,
                      'Memory',
                    ),
                    _createLineBarsData(
                      context,
                      [20, 19, 21, 20, 22, 21, 20],
                      Colors.purple,
                      'Disk',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 16,
              children: [
                _ChartLegend(color: Colors.blue, label: 'CPU'),
                _ChartLegend(color: Colors.green, label: 'Memory'),
                _ChartLegend(color: Colors.purple, label: 'Disk'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _createLineBarsData(
    BuildContext context,
    List<double> values,
    Color color,
    String label,
  ) {
    return LineChartBarData(
      spots: List.generate(
        values.length,
        (index) => FlSpot(index.toDouble(), values[index]),
      ),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
