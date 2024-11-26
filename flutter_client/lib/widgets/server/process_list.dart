// lib/widgets/server/process_list.dart
import 'package:flutter/material.dart';

class TopProcessesSection extends StatelessWidget {
  const TopProcessesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Processes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: const [
              TableRow(
                children: [
                  Text('PROCESS', style: TextStyle(color: Colors.grey)),
                  Text('CPU (%)', style: TextStyle(color: Colors.grey)),
                  Text('MEM (GB)', style: TextStyle(color: Colors.grey)),
                  Text('THREADS', style: TextStyle(color: Colors.grey)),
                ],
              ),
              // Process rows...
            ],
          ),
        ],
      ),
    );
  }
}
