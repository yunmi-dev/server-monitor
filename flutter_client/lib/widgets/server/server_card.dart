// lib/widgets/server/server_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/widgets/charts/mini_chart.dart';
import 'package:flutter_client/utils/number_utils.dart';
import 'package:flutter_client/models/time_series_data.dart';
import 'package:flutter_client/models/log_entry.dart';

class ServerCard extends StatelessWidget {
  final Server server;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool showDetailedStats;
  final bool animate;

  const ServerCard({
    super.key,
    required this.server,
    this.onTap,
    this.onMoreTap,
    this.showDetailedStats = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (showDetailedStats) ...[
                const SizedBox(height: AppConstants.spacing),
                _buildResourceStats(context),
              ],
              const SizedBox(height: AppConstants.spacing),
              _buildMetrics(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: server.status.color,
            boxShadow: [
              BoxShadow(
                color: server.status.color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                server.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Uptime: ${server.uptime}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (server.status == ServerStatus.warning ||
            server.status == ServerStatus.critical)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  server.recentLogs
                      .where((log) =>
                          log.level == LogLevel.warning ||
                          log.level == LogLevel.error ||
                          log.level == LogLevel.critical)
                      .length
                      .toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMoreTap ?? () => _showServerOptions(context),
          tooltip: '서버 옵션',
        ),
      ],
    );
  }

  Widget _buildResourceStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ResourceChart(
            label: 'CPU Usage',
            value: server.resources.cpu,
            data: server.resources.cpuHistory,
            color: Colors.blue,
            animate: animate,
          ),
        ),
        const SizedBox(width: AppConstants.spacing),
        Expanded(
          child: _ResourceChart(
            label: 'Memory Usage',
            value: server.resources.memory,
            data: server.resources.memoryHistory,
            color: Colors.green,
            animate: animate,
          ),
        ),
        const SizedBox(width: AppConstants.spacing),
        Expanded(
          child: _ResourceChart(
            label: 'Disk Usage',
            value: server.resources.disk,
            data: server.resources.diskHistory,
            color: Colors.purple,
            animate: animate,
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final network = server.resources.network;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MetricItem(
          label: 'CPU',
          value: '${server.resources.cpu.toStringAsFixed(1)}%',
          color: Colors.blue,
        ),
        _MetricItem(
          label: 'Memory',
          value: '${server.resources.memory.toStringAsFixed(1)}%',
          color: Colors.green,
        ),
        _MetricItem(
          label: 'Disk',
          value: '${server.resources.disk.toStringAsFixed(1)}%',
          color: Colors.purple,
        ),
        // TODO: Server 모델의 network 필드 nullable 여부 확인 후 불필요한 null 체크 제거
        if (network != null && network.isNotEmpty) // null 체크와 빈 문자열 체크
          _MetricItem(
            label: 'Network',
            value: NumberUtils.formatBandwidth(
                double.parse(network)), // 이미 String이므로 변환 불필요
            color: Colors.orange,
          ),
      ],
    );
  }

  void _showServerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Restart Server'),
              onTap: () {
                Navigator.pop(context);
                _showRestartConfirmation(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('Open Console'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to console
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Server Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            if (server.status == ServerStatus.offline)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Start Server'),
                onTap: () {
                  Navigator.pop(context);
                  // Start server
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.stop),
                title: const Text('Stop Server'),
                onTap: () {
                  Navigator.pop(context);
                  _showStopConfirmation(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRestartConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Server'),
        content: Text('Are you sure you want to restart ${server.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement server restart
    }
  }

  Future<void> _showStopConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Server'),
        content: Text('Are you sure you want to stop ${server.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement server stop
    }
  }
}

class _ResourceChart extends StatelessWidget {
  final String label;
  final double value;
  final List<TimeSeriesData> data;
  final Color color;
  final bool animate;

  const _ResourceChart({
    required this.label,
    required this.value,
    required this.data,
    required this.color,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: MiniChart(
            data: data,
            color: color,
            animate: animate,
          ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
