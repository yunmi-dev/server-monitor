// lib/shared/widgets/notification_overlay.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'in_app_notification.dart';

class NotificationOverlay {
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    Color? backgroundColor,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    _dismissTimer?.cancel();
    _currentOverlay?.remove();

    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _NotificationAnimation(
          child: InAppNotification(
            title: title,
            message: message,
            backgroundColor: backgroundColor,
            onTap: () {
              _currentOverlay?.remove();
              _currentOverlay = null;
              onTap?.call();
            },
            onDismiss: () {
              _currentOverlay?.remove();
              _currentOverlay = null;
            },
          ),
        ),
      ),
    );

    _currentOverlay = overlay;
    Overlay.of(context).insert(overlay);

    _dismissTimer = Timer(duration, () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }
}

class _NotificationAnimation extends StatefulWidget {
  final Widget child;

  const _NotificationAnimation({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<_NotificationAnimation> createState() => _NotificationAnimationState();
}

class _NotificationAnimationState extends State<_NotificationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
