// lib/widgets/common/status_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/models/server.dart';

class StatusIndicator extends StatelessWidget {
  final ServerStatus status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status.color,
        boxShadow: [
          BoxShadow(
            color: status.color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
