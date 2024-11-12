// lib/features/server_list/widgets/server_list_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/models/server.dart';

class ServerListItem extends StatelessWidget {
  final Server server;
  final VoidCallback onTap;

  const ServerListItem({
    Key? key,
    required this.server,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
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
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: server.isOnline ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    server.type,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricsRow(context),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uptime: ${server.metrics.uptime}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    server.location,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetric(
          label: 'CPU',
          value: server.metrics.cpu,
          color: Theme.of(context).primaryColor,
        ),
        _buildMetric(
          label: 'RAM',
          value: server.metrics.memory,
          color: Colors.blue,
        ),
        _buildMetric(
          label: 'DISK',
          value: server.metrics.disk,
          color: Colors.green,
        ),
        _buildMetric(
          label: 'NET',
          value: server.metrics.network,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetric({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
