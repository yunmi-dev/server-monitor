// lib/core/api/api_endpoints.dart

class ApiEndpoints {
  static const String baseUrl = 'http://your-api-url'; // TODO: 실제 API URL로 변경

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';

  // Server endpoints
  static const String servers = '/servers';
  static const String serverMetrics = '/servers/metrics';
  static const String serverProcesses = '/servers/processes';
}
