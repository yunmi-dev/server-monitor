// lib/widgets/server/server_metrics_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/resource_usage.dart';
import 'package:flutter_client/config/colors.dart';
import 'package:flutter_client/utils/number_utils.dart';

class ServerMetricsRow extends StatelessWidget {
  final ResourceUsage resources;

  const ServerMetricsRow({
    super.key,
    required this.resources,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MetricIndicator(
          label: 'CPU',
          value: resources.cpu,
          icon: Icons.memory,
          color: AppColors.cpuColor,
          warning: resources.isCpuWarning,
          tooltip: 'CPU 사용량',
        ),
        _MetricIndicator(
          label: 'Memory',
          value: resources.memory,
          icon: Icons.storage,
          color: AppColors.memoryColor,
          warning: resources.isMemoryWarning,
          tooltip: 'Memory 사용량',
        ),
        _MetricIndicator(
          label: 'Disk',
          value: resources.disk,
          icon: Icons.disc_full,
          color: AppColors.diskColor,
          warning: resources.isDiskWarning,
          tooltip: 'Disk 사용량',
        ),
        _NetworkIndicator(network: resources.network),
      ],
    );
  }
}

class _MetricIndicator extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool warning;
  final String tooltip;

  const _MetricIndicator({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.warning = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = warning ? AppColors.warningColor : color;

    return Tooltip(
      message: '$tooltip: ${value.toStringAsFixed(1)}%',
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: value / 100,
                  backgroundColor: effectiveColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                  strokeWidth: 4,
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: warning
                    ? AppColors.warningColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: effectiveColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _NetworkIndicator extends StatelessWidget {
  final String network;

  const _NetworkIndicator({
    required this.network,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '네트워크 사용량: $network',
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.networkColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.network_check,
              color: AppColors.networkColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Network',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            NumberUtils.formatDataRate(network),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.networkColor,
                ),
          ),
        ],
      ),
    );
  }
}
