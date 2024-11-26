// lib/widgets/logs/log_entry_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_client/models/log_entry.dart';

class LogEntryCard extends StatelessWidget {
  final LogEntry log;
  final String searchQuery;
  final VoidCallback onTap;

  const LogEntryCard({
    super.key,
    required this.log,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getLevelIcon(log.level),
                    color: _getLevelColor(log.level),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.component,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(log.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (searchQuery.isEmpty)
                Text(log.message)
              else
                _buildHighlightedText(context, log.message, searchQuery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
  ) {
    if (query.isEmpty) return Text(text);

    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) return Text(text);

    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in matches) {
      if (match.start != lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd != text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_outlined;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.critical:
        return Icons.dangerous_outlined;
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}
