// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/dashboard/dashboard_provider.dart';
import '../../features/server_list/server_list_provider.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Shared Preferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton(prefs);

  // API Client
  getIt.registerSingleton(ApiClient(getIt<SharedPreferences>()));

  // Providers
  getIt.registerLazySingleton(() => AuthProvider());
  getIt.registerLazySingleton(() => DashboardProvider());
  getIt.registerLazySingleton(() => ServerListProvider());
}
