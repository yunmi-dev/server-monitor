// lib/utils/chart_utils.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_client/config/constants.dart';

class ChartUtils {
  static final _percentFormatter = NumberFormat.percentPattern();
  static final _numberFormatter = NumberFormat.compactCurrency(
    decimalDigits: 1,
    symbol: '',
  );
  static final _dateFormatter = DateFormat('HH:mm');

  static String formatNumber(double value, {bool isPercentage = false}) {
    if (isPercentage) {
      return _percentFormatter.format(value / 100);
    }
    return _numberFormatter.format(value);
  }

  static Color getResourceColor(BuildContext context, double value) {
    final colorScheme = Theme.of(context).colorScheme;
    if (value >= AppConstants.criticalThreshold) {
      return colorScheme.error;
    } else if (value >= AppConstants.warningThreshold) {
      return colorScheme.errorContainer;
    }
    return colorScheme.primary;
  }

  static BarTouchData getBarTouchData({
    required BuildContext context,
    String Function(double)? valueFormatter,
    bool showTooltip = true,
  }) {
    return BarTouchData(
      enabled: showTooltip,
      touchTooltipData: BarTouchTooltipData(
        tooltipMargin: AppConstants.spacing / 2,
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing / 2,
          vertical: AppConstants.spacing / 4,
        ),
        tooltipBorder: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        tooltipRoundedRadius: AppConstants.cardBorderRadius / 2,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final value = valueFormatter?.call(rod.toY) ??
              _percentFormatter.format(rod.toY / 100);
          return BarTooltipItem(
            value,
            Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          );
        },
      ),
      handleBuiltInTouches: true,
      mouseCursorResolver: (event, response) {
        return response == null ? MouseCursor.defer : SystemMouseCursors.click;
      },
    );
  }

  static FlGridData getDefaultGridData(BuildContext context) {
    final surfaceVariant =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 20,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: surfaceVariant.withOpacity(0.5),
          strokeWidth: 0.5,
          dashArray: [5, 5],
        );
      },
    );
  }

  static FlBorderData getDefaultBorderData(BuildContext context) {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
    );
  }

  static FlTitlesData getDefaultTitlesData(
    BuildContext context, {
    bool showTime = true,
    String Function(double)? leftTitleFormatter,
    double? interval,
  }) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: showTime,
          reservedSize: 32,
          interval: interval ?? 1,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: AppConstants.spacing / 2,
              child: Text(
                _dateFormatter.format(
                  DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: 20,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: AppConstants.spacing / 2,
              child: Text(
                leftTitleFormatter?.call(value) ??
                    _percentFormatter.format(value / 100),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  static String formatChartValue(double value, {bool showPercent = true}) {
    if (showPercent) {
      return _percentFormatter.format(value / 100);
    }
    return _numberFormatter.format(value);
  }

  static String formatTimestamp(DateTime timestamp) {
    return _dateFormatter.format(timestamp);
  }

  static List<Color> getDefaultColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];
  }
}
