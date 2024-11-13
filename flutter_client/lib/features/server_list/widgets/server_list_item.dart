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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricsRow(),
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
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color backgroundColor;
    String text;

    if (!server.isOnline) {
      backgroundColor = Colors.red;
      text = 'Offline';
    } else if (server.metrics.cpu > 90 ||
        server.metrics.memory > 90 ||
        server.metrics.disk > 90) {
      backgroundColor = Colors.red;
      text = 'Critical';
    } else if (server.metrics.cpu > 80 ||
        server.metrics.memory > 80 ||
        server.metrics.disk > 80) {
      backgroundColor = Colors.orange;
      text = 'Warning';
    } else {
      backgroundColor = Colors.green;
      text = server.type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        border: Border.all(color: backgroundColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: backgroundColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric(
          label: 'CPU',
          value: server.metrics.cpu,
          color: Colors.blue,
        ),
        _buildMetric(
          label: 'Memory',
          value: server.metrics.memory,
          color: Colors.purple,
        ),
        _buildMetric(
          label: 'Disk',
          value: server.metrics.disk,
          color: Colors.green,
        ),
        _buildMetric(
          label: 'Network',
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
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
