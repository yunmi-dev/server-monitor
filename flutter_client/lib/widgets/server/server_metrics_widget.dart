// lib/widgets/server/server_metrics_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/widgets/charts/common/status_indicator.dart';
import 'package:flutter_client/widgets/charts/common/resource_indicator.dart';

class ServerMetricsWidget extends StatelessWidget {
  final String serverId;
  final Duration updateInterval;

  const ServerMetricsWidget({
    super.key,
    required this.serverId,
    this.updateInterval = const Duration(seconds: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, provider, child) {
        final server = provider.servers.firstWhere((s) => s.id == serverId);

        return Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '리소스 사용량',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    StatusIndicator(status: server.status),
                  ],
                ),
                const SizedBox(height: 16),
                ResourceIndicator(
                  label: 'CPU',
                  value: server.resources.cpu,
                  icon: Icons.memory,
                  color: _getResourceColor(server.resources.cpu),
                ),
                const SizedBox(height: 8),
                ResourceIndicator(
                  label: '메모리',
                  value: server.resources.memory,
                  icon: Icons.storage,
                  color: _getResourceColor(server.resources.memory),
                ),
                const SizedBox(height: 8),
                ResourceIndicator(
                  label: '디스크',
                  value: server.resources.disk,
                  icon: Icons.disc_full,
                  color: _getResourceColor(server.resources.disk),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getResourceColor(double value) {
    if (value >= AppConstants.criticalThreshold) {
      return Colors.red;
    } else if (value >= AppConstants.warningThreshold) {
      return Colors.orange;
    }
    return Colors.green;
  }
}
