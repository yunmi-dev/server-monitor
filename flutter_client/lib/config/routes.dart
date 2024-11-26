// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_client/constants/route_paths.dart';
import 'package:flutter_client/screens/auth/login_screen.dart';
import 'package:flutter_client/screens/auth/signup_screen.dart';
import 'package:flutter_client/screens/auth/forgot_password_screen.dart';
import 'package:flutter_client/screens/splash_screen.dart';
import 'package:flutter_client/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_client/screens/server/server_list_screen.dart';
import 'package:flutter_client/screens/server/server_details_screen.dart';
import 'package:flutter_client/screens/server/server_add_screen.dart';
import 'package:flutter_client/screens/alerts/alerts_screen.dart';
import 'package:flutter_client/screens/settings/settings_screen.dart'
    as settings;
import 'package:flutter_client/screens/settings/profile_screen.dart';
import 'package:flutter_client/screens/settings/notifications_screen.dart';
import 'package:flutter_client/screens/logs/logs_screen.dart';

class AppRoutes {
  static const double _defaultDuration = 0.3;
  static const Curve _defaultEasing = Curves.easeInOut;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget screen;
    RouteTransition transition = _getTransitionType(settings.name);

    switch (settings.name) {
      // Auth Routes
      case RoutePaths.splash:
        screen = const SplashScreen();
        break;

      case RoutePaths.login:
        screen = const LoginScreen();
        break;

      case RoutePaths.signup:
        screen = const SignupScreen();
        break;

      case RoutePaths.forgotPassword:
        screen = const ForgotPasswordScreen();
        break;

      // Main Routes
      case RoutePaths.dashboard:
        screen = const DashboardScreen();
        break;

      case RoutePaths.servers:
        screen = const ServerListScreen();
        break;

      case RoutePaths.alerts:
        screen = const AlertsScreen();
        break;

      case RoutePaths.settings:
        screen = const settings.SettingsScreen();
        break;

      // Server Related Routes
      case RoutePaths.serverDetails:
        final args = settings.arguments as Map<String, dynamic>;
        final server = args['server'] as Server; // Server 모델 사용
        screen = ServerDetailsScreen(
          serverId: server.id,
          server: server, // Server 객체 전달
        );
        break;

      case RoutePaths.serverAdd:
        screen = const ServerAddScreen();
        break;

      // Settings Related Routes
      case RoutePaths.profile:
        screen = const ProfileScreen();
        break;

      case RoutePaths.notifications:
        screen = const NotificationsScreen();
        break;

      // Logs & Monitoring
      case RoutePaths.logs:
        final args = settings.arguments as Map<String, dynamic>?;
        screen = LogsScreen(serverId: args?['serverId'] as String?);
        break;

      default:
        screen = const SplashScreen();
    }

    return _buildRoute(screen, settings, transition);
  }

  static Route<dynamic> _buildRoute(
    Widget screen,
    RouteSettings settings,
    RouteTransition transition,
  ) {
    switch (transition) {
      case RouteTransition.fade:
        return _buildFadeRoute(screen, settings: settings);
      case RouteTransition.slide:
        return _buildSlideRoute(screen, settings: settings);
      case RouteTransition.sharedAxis:
        return _buildSharedAxisRoute(screen, settings: settings);
      case RouteTransition.scale:
        return _buildScaleRoute(screen, settings: settings);
    }
  }

  static RouteTransition _getTransitionType(String? routeName) {
    switch (routeName) {
      case RoutePaths.splash:
      case RoutePaths.dashboard:
        return RouteTransition.fade;

      case RoutePaths.login:
      case RoutePaths.signup:
      case RoutePaths.forgotPassword:
        return RouteTransition.slide;

      case RoutePaths.serverAdd:
      case RoutePaths.profile:
      case RoutePaths.notifications:
        return RouteTransition.scale;

      default:
        return RouteTransition.sharedAxis;
    }
  }

  static Route<T> _buildFadeRoute<T>(
    Widget page, {
    RouteSettings? settings,
    double duration = _defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: Duration(milliseconds: (duration * 1000).toInt()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: _defaultEasing,
          ),
          child: child,
        );
      },
    );
  }

  static Route<T> _buildSlideRoute<T>(
    Widget page, {
    RouteSettings? settings,
    AxisDirection direction = AxisDirection.right,
    double duration = _defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: Duration(milliseconds: (duration * 1000).toInt()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(direction == AxisDirection.left ? 1.0 : -1.0, 0.0);
        var tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: _defaultEasing));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static Route<T> _buildSharedAxisRoute<T>(
    Widget page, {
    RouteSettings? settings,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
    double duration = _defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: Duration(milliseconds: (duration * 1000).toInt()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        );
      },
    );
  }

  static Route<T> _buildScaleRoute<T>(
    Widget page, {
    RouteSettings? settings,
    double duration = _defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: Duration(milliseconds: (duration * 1000).toInt()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: _defaultEasing,
          ),
        );

        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: _defaultEasing,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

enum RouteTransition {
  fade,
  slide,
  sharedAxis,
  scale,
}
