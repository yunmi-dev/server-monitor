// lib/widgets/alert_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/alert.dart';

class AlertListItem extends StatelessWidget {
  final Alert alert;
  final bool isSelected;
  final ValueChanged<bool> onSelect;

  const AlertListItem({
    super.key,
    required this.alert,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            _getSeverityIcon(alert.severity),
            color: _getSeverityColor(alert.severity),
          ),
          if (!alert.isRead)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        alert.title,
        style: TextStyle(
          fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.message),
          const SizedBox(height: 4),
          Row(
            children: [
              if (alert.category != null)
                Chip(
                  label: Text(
                    alert.category!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              const Spacer(),
              Text(
                _formatTimestamp(alert.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) => onSelect(value ?? false),
      ),
    );
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    return severity.icon;
  }

  Color _getSeverityColor(AlertSeverity severity) {
    return severity.color;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
