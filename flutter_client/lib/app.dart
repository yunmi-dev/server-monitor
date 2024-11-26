// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'providers/server_provider.dart';
import 'config/constants.dart';
import 'providers/theme_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'FLick',
          theme: AppTheme.darkTheme(),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
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

  const _AppWrapper({
    super.key,
    required this.child,
  });

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
        if (!provider.hasNetworkError) return const SizedBox.shrink();

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
                        provider.retryConnections();
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
