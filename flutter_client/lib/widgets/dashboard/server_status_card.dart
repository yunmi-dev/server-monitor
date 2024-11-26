// lib/widgets/dashboard/server_status_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/server_metrics.dart';

class ServerStatusCard extends StatelessWidget {
  final ServerMetrics metrics;
  final VoidCallback? onTap;

  const ServerStatusCard({
    Key? key,
    required this.metrics,
    this.onTap,
  }) : super(key: key);

  Color _getStatusColor(double value) {
    if (value >= 90) return Colors.red;
    if (value >= 75) return Colors.orange;
    if (value >= 60) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    metrics.serverName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: _getStatusColor(metrics.cpuUsage),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                context,
                'CPU',
                metrics.cpuUsage,
                Icons.memory,
              ),
              const SizedBox(height: 8),
              _buildMetricRow(
                context,
                'Memory',
                metrics.memoryUsage,
                Icons.storage,
              ),
              const SizedBox(height: 8),
              _buildMetricRow(
                context,
                'Disk',
                metrics.diskUsage,
                Icons.disc_full,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(label),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(value)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${value.toStringAsFixed(1)}%'),
      ],
    );
  }
}
