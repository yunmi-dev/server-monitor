// lib/features/dashboard/widgets/distribution_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DistributionCard extends StatelessWidget {
  const DistributionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: [
                    _generateBarGroup(0, [30, 20, 15], context),
                    _generateBarGroup(1, [45, 35, 25], context),
                    _generateBarGroup(2, [35, 25, 20], context),
                    _generateBarGroup(3, [55, 45, 35], context),
                    _generateBarGroup(4, [40, 30, 25], context),
                    _generateBarGroup(5, [45, 35, 30], context),
                    _generateBarGroup(6, [50, 40, 35], context),
                    _generateBarGroup(7, [45, 35, 30], context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('CPU', Theme.of(context).primaryColor),
                const SizedBox(width: 24),
                _buildLegendItem('RAM', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('SSD', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _generateBarGroup(
    int x,
    List<double> values,
    BuildContext context,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: values[0],
          color: Theme.of(context).primaryColor,
          width: 8,
        ),
        BarChartRodData(
          toY: values[1],
          color: Colors.blue,
          width: 8,
        ),
        BarChartRodData(
          toY: values[2],
          color: Colors.green,
          width: 8,
        ),
      ],
      showingTooltipIndicators: [],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
