// lib/widgets/server/circular_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/utils/number_utils.dart';

class CircularIndicator extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;
  final double size;
  final bool showLabel;
  final bool animate;
  final String? tooltip;
  final double? trend;

  const CircularIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.size = 120.0,
    this.showLabel = true,
    this.animate = true,
    this.tooltip,
    this.trend,
  });

  @override
  State<CircularIndicator> createState() => _CircularIndicatorState();
}

class _CircularIndicatorState extends State<CircularIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CircularIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      if (widget.animate) {
        _controller
          ..reset()
          ..forward();
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ??
          '${widget.label}: ${widget.value.toStringAsFixed(1)}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CircularIndicatorPainter(
                        progress: _animation.value,
                        color: widget.color,
                        backgroundColor: widget.color.withOpacity(0.2),
                      ),
                    );
                  },
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null)
                        Icon(
                          widget.icon,
                          color: widget.color,
                          size: widget.size * 0.2,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.value.toStringAsFixed(1)}%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: widget.color,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (widget.trend != null) ...[
                        const SizedBox(height: 2),
                        _buildTrendIndicator(context),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.showLabel) ...[
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    if (widget.trend == null) return const SizedBox();

    final isPositive = widget.trend! > 0;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final color = isPositive ? Colors.red : Colors.green;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        Text(
          NumberUtils.formatPercent(widget.trend!.abs()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _CircularIndicatorPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularIndicatorPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 진행도 원호
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90도 (12시 방향에서 시작)
      progress * 6.2832, // 2π
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
