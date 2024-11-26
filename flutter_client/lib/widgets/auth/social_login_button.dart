// lib/widgets/auth/social_login_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_client/config/constants.dart';

class SocialLoginButton extends StatefulWidget {
  final String provider;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color? textColor;
  final String iconPath;
  final bool isLoading;

  const SocialLoginButton({
    Key? key,
    required this.provider,
    required this.onPressed,
    required this.backgroundColor,
    required this.iconPath,
    this.textColor,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

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
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
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
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            boxShadow: [
              if (!_isPressed)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing * 1.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.textColor ?? Colors.white,
                          ),
                        ),
                      )
                    else ...[
                      Image.asset(
                        widget.iconPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: AppConstants.spacing),
                      Text(
                        'Continue with ${widget.provider}',
                        style: TextStyle(
                          color: widget.textColor ?? Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Themed versions of the SocialLoginButton
class AppleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const AppleLoginButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      provider: 'Apple',
      onPressed: onPressed,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      iconPath: 'assets/icons/apple.png',
      isLoading: isLoading,
    );
  }
}

class KakaoLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const KakaoLoginButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      provider: 'Kakao',
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFEE500),
      textColor: const Color(0xFF000000),
      iconPath: 'assets/icons/kakao.png',
      isLoading: isLoading,
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleLoginButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      provider: 'Google',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      iconPath: 'assets/icons/google.png',
      isLoading: isLoading,
    );
  }
}

class FacebookLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const FacebookLoginButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      provider: 'Facebook',
      onPressed: onPressed,
      backgroundColor: const Color(0xFF1877F2),
      textColor: Colors.white,
      iconPath: 'assets/icons/facebook.png',
      isLoading: isLoading,
    );
  }
}
