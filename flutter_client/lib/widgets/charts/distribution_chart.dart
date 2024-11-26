// lib/widgets/charts/distribution_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/chart_data.dart';
import 'package:flutter_client/utils/chart_utils.dart';
import 'package:flutter_client/providers/distribution_provider.dart';

class DistributionChart extends ConsumerWidget {
  final List<DistributionData> data;
  final String title;
  final double maxValue;
  final bool showLegend;
  final bool animate;
  final bool showTooltip;
  final bool showGrid;

  const DistributionChart({
    super.key,
    required this.data,
    required this.title,
    this.maxValue = 100,
    this.showLegend = true,
    this.animate = true,
    this.showTooltip = true,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(distributionLoadingProvider);

    return Card(
      margin: const EdgeInsets.all(AppConstants.spacing),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _RefreshButton(
                  isLoading: isLoading,
                  onRefresh: () => _handleRefresh(ref),
                ),
              ],
            ),
            if (data.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacing * 2),
                  child: Text('No data available'),
                ),
              )
            else ...[
              const SizedBox(height: AppConstants.spacing),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue,
                    barTouchData: ChartUtils.getBarTouchData(
                      context: context,
                      showTooltip: showTooltip,
                      valueFormatter: (value) {
                        return ChartUtils.formatNumber(value,
                            isPercentage: true);
                      },
                    ),
                    titlesData: ChartUtils.getDefaultTitlesData(
                      context,
                      interval: data.length > 6 ? 2 : 1,
                    ),
                    gridData: showGrid
                        ? ChartUtils.getDefaultGridData(context)
                        : const FlGridData(show: false),
                    borderData: ChartUtils.getDefaultBorderData(context),
                    barGroups: _createBarGroups(context),
                    alignment: BarChartAlignment.spaceAround,
                  ),
                  duration: animate
                      ? AppConstants.chartAnimationDuration
                      : Duration.zero,
                ),
              ),
              if (showLegend) ...[
                const SizedBox(height: AppConstants.spacing),
                _buildLegend(context),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    try {
      await ref.read(distributionDataProvider.notifier).fetchLatestData();
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: AppConstants.spacing / 2),
                Expanded(
                  child: Text(
                    e.toString().contains('TimeoutException')
                        ? AppConstants.timeoutError
                        : e.toString().contains('SocketException')
                            ? AppConstants.networkError
                            : AppConstants.unknownError,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(ref.context).colorScheme.error,
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () => _handleRefresh(ref),
            ),
          ),
        );
      }
    }
  }

  List<BarChartGroupData> _createBarGroups(BuildContext context) {
    final colors = ChartUtils.getDefaultColors(context);

    return List.generate(data.length, (index) {
      final item = data[index];
      return BarChartGroupData(
        x: index,
        barRods: List.generate(
          item.values.length,
          (valueIndex) {
            final value = item.values[valueIndex];
            return BarChartRodData(
              toY: value,
              color: colors[valueIndex % colors.length],
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildLegend(BuildContext context) {
    final colors = ChartUtils.getDefaultColors(context);

    return Wrap(
      spacing: AppConstants.spacing,
      runSpacing: AppConstants.spacing / 2,
      children: data.first.categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final color = colors[index % colors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: AppConstants.spacing / 4),
            Text(
              category,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const _RefreshButton({
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.refresh),
      onPressed: isLoading ? null : onRefresh,
      tooltip: '새로고침',
    );
  }
}
