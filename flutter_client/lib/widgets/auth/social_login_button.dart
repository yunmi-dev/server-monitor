// lib/widgets/auth/social_login_button.dart
import 'package:flutter/material.dart';

class SocialLoginButton extends StatefulWidget {
  final String provider;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color? textColor;
  final String iconPath;
  final bool isLoading;
  final String text;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    required this.backgroundColor,
    required this.iconPath,
    required this.text,
    this.textColor,
    this.isLoading = false,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed,
        child: Container(
          width: double.infinity,
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Image.asset(
            widget.iconPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
