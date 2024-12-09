// lib/widgets/charts/resource_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ResourceOverviewChart extends StatelessWidget {
  const ResourceOverviewChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[800],
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[800],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = '00:00';
                      break;
                    case 3:
                      text = '03:00';
                      break;
                    case 6:
                      text = '06:00';
                      break;
                    case 9:
                      text = '09:00';
                      break;
                    case 12:
                      text = '12:00';
                      break;
                    default:
                      return Container();
                  }
                  return Text(text, style: style);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  );
                },
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
          maxX: 12,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            // CPU Line
            LineChartBarData(
              spots: [
                const FlSpot(0, 65),
                const FlSpot(2, 70),
                const FlSpot(4, 55),
                const FlSpot(6, 85),
                const FlSpot(8, 75),
                const FlSpot(10, 60),
                const FlSpot(12, 65),
              ],
              isCurved: true,
              color: const Color(0xFFF06292),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFF06292).withOpacity(0.1),
              ),
            ),
            // Memory Line
            LineChartBarData(
              spots: [
                const FlSpot(0, 45),
                const FlSpot(2, 50),
                const FlSpot(4, 45),
                const FlSpot(6, 55),
                const FlSpot(8, 45),
                const FlSpot(10, 40),
                const FlSpot(12, 45),
              ],
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
            // Network Line
            LineChartBarData(
              spots: [
                const FlSpot(0, 25),
                const FlSpot(2, 30),
                const FlSpot(4, 25),
                const FlSpot(6, 35),
                const FlSpot(8, 25),
                const FlSpot(10, 20),
                const FlSpot(12, 25),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
