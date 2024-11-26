// lib/screens/dashboard/tabs/performance_tab.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformanceTab extends StatelessWidget {
  const PerformanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResourceOverview(context),
        const SizedBox(height: 24),
        _buildServerStatus(context),
        const SizedBox(height: 24),
        _buildTopProcessesTable(context),
        const SizedBox(height: 24),
        _buildResourceDistribution(context),
      ],
    );
  }

  Widget _buildResourceOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resource Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 1,
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
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()}:00',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  minX: 0,
                  maxX: 23,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    _createLineBarsData(
                      [40, 35, 45, 38, 42, 39, 41, 43, 40, 38, 35],
                      Colors.blue,
                      'CPU',
                    ),
                    _createLineBarsData(
                      [65, 62, 68, 63, 66, 64, 65, 67, 70, 68, 65],
                      Colors.green,
                      'Memory',
                    ),
                    _createLineBarsData(
                      [20, 19, 21, 20, 22, 21, 20, 23, 25, 24, 22],
                      Colors.purple,
                      'Disk',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, 'CPU', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem(context, 'Memory', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem(context, 'Disk', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _createLineBarsData(
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

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
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
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildServerStatus(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusMetric(
                    context,
                    'Uptime',
                    '15 days 7 hours',
                    Icons.timer_outlined,
                  ),
                ),
                Expanded(
                  child: _buildStatusMetric(
                    context,
                    'Load Average',
                    '1.52, 1.65, 1.48',
                    Icons.speed_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTopProcessesTable(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Processes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Process')),
                  DataColumn(
                    label: Text('CPU (%)'),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Memory (GB)'),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Threads'),
                    numeric: true,
                  ),
                ],
                rows: [
                  _buildProcessRow('nginx', 2.5, 1.2, 4),
                  _buildProcessRow('mongodb', 4.0, 3.5, 12),
                  _buildProcessRow('node', 3.2, 2.8, 8),
                  _buildProcessRow('redis', 1.8, 1.0, 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildProcessRow(
    String name,
    double cpu,
    double memory,
    int threads,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(name)),
        DataCell(Text(cpu.toStringAsFixed(1))),
        DataCell(Text(memory.toStringAsFixed(1))),
        DataCell(Text(threads.toString())),
      ],
    );
  }

  Widget _buildResourceDistribution(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resource Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const times = [
                            '0:00',
                            '4:00',
                            '8:00',
                            '12:00',
                            '16:00',
                            '20:00'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < times.length) {
                            return Text(times[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _createBarGroup(0, [30, 45, 25]),
                    _createBarGroup(1, [35, 40, 25]),
                    _createBarGroup(2, [40, 35, 25]),
                    _createBarGroup(3, [45, 35, 20]),
                    _createBarGroup(4, [40, 40, 20]),
                    _createBarGroup(5, [35, 45, 20]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _createBarGroup(int x, List<double> values) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: values[0],
          color: Colors.blue,
          width: 15,
        ),
        BarChartRodData(
          toY: values[1],
          color: Colors.green,
          width: 15,
        ),
        BarChartRodData(
          toY: values[2],
          color: Colors.purple,
          width: 15,
        ),
      ],
    );
  }
}
