// lib/widgets/monitoring/resource_gauge.dart
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;

class ResourceGauge extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const ResourceGauge({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _GaugePainter(
              value: value,
              color: color,
              backgroundColor: Colors.grey.withOpacity(0.2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 8),
                  Text(
                    '${value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = 150.0;
    const sweepAngle = 240.0;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      vector.radians(startAngle),
      vector.radians(sweepAngle),
      false,
      backgroundPaint,
    );

    // Draw value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      vector.radians(startAngle),
      vector.radians(sweepAngle * (value / 100)),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
