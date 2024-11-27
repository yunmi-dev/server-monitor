// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client/config/theme.dart';
import 'package:flutter_client/config/routes.dart';
import 'package:flutter_client/providers/auth_provider.dart';
import 'package:flutter_client/screens/splash_screen.dart';
import 'package:flutter_client/screens/auth/login_screen.dart';
import 'package:flutter_client/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/providers/theme_provider.dart';
import 'package:flutter_client/services/navigation_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // 시스템 UI 오버레이 스타일 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'FLick',
          theme: AppTheme.darkTheme(), // 항상 다크 테마 사용
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService.navigatorKey,
          home: const AppNavigator(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            return _AppWrapper(child: child!);
          },
        );
      },
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isInitializing) {
          return const SplashScreen();
        }

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}

class _AppWrapper extends StatelessWidget {
  final Widget child;

  const _AppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          _buildNetworkStatusBar(context),
          _buildGlobalLoading(context),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusBar(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        // 네트워크 오류 검사 로직 개선
        final hasNetworkError =
            provider.error?.toLowerCase().contains('network') ?? false;
        if (!hasNetworkError) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            child: Container(
              color: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.all(AppConstants.spacing),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppConstants.spacing),
                    const Expanded(
                      child: Text(
                        '네트워크 연결이 불안정합니다',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        provider.refreshAll();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlobalLoading(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoading) return const SizedBox.shrink();

        return Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
