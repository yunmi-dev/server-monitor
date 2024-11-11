// lib/features/dashboard/widgets/top_processes_card.dart

import 'package:flutter/material.dart';

class TopProcessesCard extends StatelessWidget {
  const TopProcessesCard({Key? key}) : super(key: key);

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
              'Top Processes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('PROCESS'),
                    _buildTableHeader('CPU (%)'),
                    _buildTableHeader('RAM (GB)'),
                    _buildTableHeader('NETWORK'),
                  ],
                ),
                ...List.generate(
                  4,
                  (index) => _buildTableRow(
                    process: ['nginx', 'mongodb', 'node', 'redis'][index],
                    cpu: [2.5, 4.2, 1.8, 1.2][index],
                    ram: [1.8, 3.1, 2.2, 0.8][index],
                    network: ['150MB/s', '80MB/s', '45MB/s', '20MB/s'][index],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  TableRow _buildTableRow({
    required String process,
    required double cpu,
    required double ram,
    required String network,
  }) {
    return TableRow(
      children: [
        _buildTableCell(
          process,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        _buildTableCell('${cpu.toStringAsFixed(1)}%'),
        _buildTableCell('${ram.toStringAsFixed(1)}'),
        _buildTableCell(network),
      ],
    );
  }

  Widget _buildTableCell(
    String text, {
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
