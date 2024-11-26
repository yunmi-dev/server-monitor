// lib/widgets/logs/log_filter_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/log_entry.dart';

class LogFilterChip extends StatelessWidget {
  final LogLevel level;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final bool showCount;
  final int? count;

  const LogFilterChip({
    super.key,
    required this.level,
    required this.isSelected,
    required this.onSelected,
    this.showCount = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final color = level.color;
    final theme = Theme.of(context);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level.icon,
            size: 16,
            color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(level.label),
          if (showCount && count != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      isSelected ? color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: color.withOpacity(0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      pressElevation: 0,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class LogFilterBar extends StatelessWidget {
  final Set<LogLevel> selectedLevels;
  final ValueChanged<Set<LogLevel>> onSelectionChanged;
  final Map<LogLevel, int>? logCounts;

  const LogFilterBar({
    super.key,
    required this.selectedLevels,
    required this.onSelectionChanged,
    this.logCounts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              '로그 레벨:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              children: LogLevel.values.map((level) {
                return LogFilterChip(
                  level: level,
                  isSelected: selectedLevels.contains(level),
                  onSelected: (selected) {
                    final newSelection = Set<LogLevel>.from(selectedLevels);
                    if (selected) {
                      newSelection.add(level);
                    } else {
                      newSelection.remove(level);
                    }
                    onSelectionChanged(newSelection);
                  },
                  showCount: logCounts != null,
                  count: logCounts?[level],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
