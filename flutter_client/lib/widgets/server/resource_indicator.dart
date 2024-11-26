// lib/widgets/server/resource_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/widgets/server/circular_indicator.dart';
import 'package:flutter_client/models/resource_usage.dart';
import 'package:flutter_client/config/colors.dart';
import 'package:flutter_client/utils/number_utils.dart';

class ResourceIndicators extends StatelessWidget {
  final ResourceUsage resources;
  final bool showLabels;
  final double size;
  final VoidCallback? onTap;
  final bool animate;

  const ResourceIndicators({
    super.key,
    required this.resources,
    this.showLabels = true,
    this.size = 120.0,
    this.onTap,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularIndicator(
              label: 'CPU',
              value: resources.cpu,
              color: _getResourceColor(resources.cpu),
              icon: Icons.memory,
              size: size,
              showLabel: showLabels,
              animate: animate,
              tooltip: NumberUtils.getResourceDescription('CPU', resources.cpu),
              trend: resources.cpuHistory.isNotEmpty
                  ? resources.cpuHistory.last.value -
                      resources.cpuHistory.first.value
                  : null,
            ),
            CircularIndicator(
              label: 'Memory',
              value: resources.memory,
              color: _getResourceColor(resources.memory),
              icon: Icons.storage,
              size: size,
              showLabel: showLabels,
              animate: animate,
              tooltip:
                  NumberUtils.getResourceDescription('메모리', resources.memory),
              trend: resources.memoryHistory.isNotEmpty
                  ? resources.memoryHistory.last.value -
                      resources.memoryHistory.first.value
                  : null,
            ),
            CircularIndicator(
              label: 'Disk',
              value: resources.disk,
              color: _getResourceColor(resources.disk),
              icon: Icons.disc_full,
              size: size,
              showLabel: showLabels,
              animate: animate,
              tooltip:
                  NumberUtils.getResourceDescription('디스크', resources.disk),
              trend: resources.diskHistory.isNotEmpty
                  ? resources.diskHistory.last.value -
                      resources.diskHistory.first.value
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Color _getResourceColor(double value) {
    if (value >= 90) return AppColors.error;
    if (value >= 75) return AppColors.warning;
    if (value >= 60) return AppColors.info;
    return AppColors.success;
  }
}
