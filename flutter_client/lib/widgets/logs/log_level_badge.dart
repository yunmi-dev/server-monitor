// lib/widgets/logs/log_level_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';

class LogLevelBadge extends StatelessWidget {
  final String level;
  final bool showDelete;
  final bool showIcon;
  final double? size;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const LogLevelBadge({
    super.key,
    required this.level,
    this.showDelete = true,
    this.showIcon = true,
    this.size,
    this.onDeleted,
    this.onTap,
  });

  Color _getColor() {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (level.toLowerCase()) {
      case 'error':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'info':
        return Icons.info_outline;
      case 'debug':
        return Icons.code;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
            size != null ? size! / 2 : AppConstants.cardBorderRadius / 2),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size != null ? size! / 4 : 8.0,
            vertical: size != null ? size! / 8 : 4.0,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(
                size != null ? size! / 2 : AppConstants.cardBorderRadius / 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  _getIcon(),
                  color: color,
                  size: size != null ? size! / 2 : 16,
                ),
                SizedBox(width: size != null ? size! / 8 : 4),
              ],
              Text(
                level.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: size != null ? size! / 3 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showDelete && onDeleted != null) ...[
                SizedBox(width: size != null ? size! / 8 : 4),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(
                    Icons.close,
                    color: color,
                    size: size != null ? size! / 2 : 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
