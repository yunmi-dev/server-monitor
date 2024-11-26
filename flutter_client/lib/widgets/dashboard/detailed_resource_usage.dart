// lib/widgets/dashboard/detailed_resource_usage.dart
import 'package:flutter/material.dart';

class DetailedResourceUsage extends StatelessWidget {
  const DetailedResourceUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CPU Usage Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const _CpuCoresGrid(),
                const SizedBox(height: 24),
                const _CpuLoadAverages(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memory Usage Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const _MemoryUsageBreakdown(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disk I/O',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const _DiskIOStats(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// lib/widgets/dashboard/detailed_resource_usage.dart의 나머지 부분 구현

class _MemoryUsageBreakdown extends StatelessWidget {
  const _MemoryUsageBreakdown();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _MemoryStatCard(
                label: 'Total',
                value: '16.0',
                unit: 'GB',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MemoryStatCard(
                label: 'Used',
                value: '10.8',
                unit: 'GB',
                valueColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MemoryStatCard(
                label: 'Available',
                value: '5.2',
                unit: 'GB',
                valueColor: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Memory Distribution'),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                _MemoryUsageBar(
                  label: 'Apps',
                  percentage: 0.45,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _MemoryUsageBar(
                  label: 'Cache',
                  percentage: 0.25,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _MemoryUsageBar(
                  label: 'System',
                  percentage: 0.15,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                _MemoryUsageBar(
                  label: 'Free',
                  percentage: 0.15,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  showBorder: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MemoryLegendItem(
              label: 'Apps',
              color: Theme.of(context).colorScheme.primary,
              value: '7.2 GB',
            ),
            _MemoryLegendItem(
              label: 'Cache',
              color: Theme.of(context).colorScheme.secondary,
              value: '4.0 GB',
            ),
            _MemoryLegendItem(
              label: 'System',
              color: Theme.of(context).colorScheme.tertiary,
              value: '2.4 GB',
            ),
            _MemoryLegendItem(
              label: 'Free',
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              value: '2.4 GB',
              showBorder: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _MemoryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const _MemoryStatCard({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryUsageBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final bool showBorder;

  const _MemoryUsageBar({
    required this.label,
    required this.percentage,
    required this.color,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (percentage * 100).round(),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: showBorder
              ? Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                )
              : null,
        ),
      ),
    );
  }
}

class _MemoryLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final String value;
  final bool showBorder;

  const _MemoryLegendItem({
    required this.label,
    required this.color,
    required this.value,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: showBorder
                ? Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiskIOStats extends StatelessWidget {
  const _DiskIOStats();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DiskStatCard(
                label: 'Read Speed',
                value: '125',
                unit: 'MB/s',
                icon: Icons.arrow_downward,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DiskStatCard(
                label: 'Write Speed',
                value: '85',
                unit: 'MB/s',
                icon: Icons.arrow_upward,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _DiskOperationsChart(),
        const SizedBox(height: 24),
        const _DiskLatencyStats(),
      ],
    );
  }
}

class _DiskStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  const _DiskStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiskOperationsChart extends StatelessWidget {
  const _DiskOperationsChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I/O Operations',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              // 차트 구현은 fl_chart 등의 패키지를 사용하여 구현
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: Text('Chart Placeholder'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiskLatencyStats extends StatelessWidget {
  const _DiskLatencyStats();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latency',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _LatencyCard(
                label: 'Read',
                value: '0.8',
                unit: 'ms',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LatencyCard(
                label: 'Write',
                value: '1.2',
                unit: 'ms',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LatencyCard(
                label: 'Avg',
                value: '1.0',
                unit: 'ms',
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LatencyCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _LatencyCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CpuCoresGrid extends StatelessWidget {
  const _CpuCoresGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 8, // Number of CPU cores
      itemBuilder: (context, index) {
        return _CoreUsageCard(
          coreNumber: index,
          usage: 30 + index * 5.0,
        );
      },
    );
  }
}

class _CoreUsageCard extends StatelessWidget {
  final int coreNumber;
  final double usage;

  const _CoreUsageCard({
    required this.coreNumber,
    required this.usage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Core ${coreNumber + 1}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          LinearProgressIndicator(
            value: usage / 100,
            backgroundColor: Theme.of(context).colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            '${usage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _CpuLoadAverages extends StatelessWidget {
  const _CpuLoadAverages();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _LoadAverageCard(
          label: '1 min',
          value: 1.52,
        ),
        _LoadAverageCard(
          label: '5 min',
          value: 1.65,
        ),
        _LoadAverageCard(
          label: '15 min',
          value: 1.48,
        ),
      ],
    );
  }
}

class _LoadAverageCard extends StatelessWidget {
  final String label;
  final double value;

  const _LoadAverageCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
