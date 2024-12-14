// test/providers/server_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_client/providers/server_provider.dart';
import 'package:flutter_client/services/api_service.dart';
import 'package:flutter_client/services/websocket_service.dart';
import 'package:flutter_client/models/server.dart';
import 'package:flutter_client/models/resource_usage.dart';
import 'package:flutter_client/config/constants.dart';

class MockApiService extends Mock implements ApiService {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockServer extends Mock implements Server {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServerProvider serverProvider;
  late MockApiService mockApiService;
  late MockWebSocketService mockWebSocketService;

  setUp(() {
    mockApiService = MockApiService();
    mockWebSocketService = MockWebSocketService();

    // WebSocket mock 설정 추가
    when(() => mockWebSocketService.metricsStream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockWebSocketService.messageStream)
        .thenAnswer((_) => Stream.empty());

    serverProvider = ServerProvider(
      apiService: mockApiService,
      webSocketService: mockWebSocketService,
    );
  });

  group('ServerProvider - Server Loading', () {
    test('loadServers should update servers list on success', () async {
      // Arrange
      final mockServers = [
        const Server(
          id: '1',
          name: 'Test Server 1',
          hostname: 'test1.example.com',
          type: ServerType.linux,
          category: ServerCategory.physical,
          status: ServerStatus.online,
          resources: ResourceUsage(
            cpu: 50.0,
            memory: 60.0,
            disk: 70.0,
            network: "10 MB/s",
            history: [],
            lastUpdated: null,
          ),
          uptime: "2 days",
          processes: [],
          recentLogs: [],
        ),
        const Server(
          id: '2',
          name: 'Test Server 2',
          hostname: 'test2.example.com',
          type: ServerType.windows,
          category: ServerCategory.virtual,
          status: ServerStatus.offline,
          resources: ResourceUsage(
            cpu: 0.0,
            memory: 0.0,
            disk: 0.0,
            network: "0 MB/s",
            history: [],
            lastUpdated: null,
          ),
          uptime: "0s",
          processes: [],
          recentLogs: [],
        ),
      ];

      when(() => mockApiService.getServers())
          .thenAnswer((_) async => mockServers);

      // Act
      await serverProvider.loadServers();

      // Assert
      expect(serverProvider.servers, equals(mockServers));
      expect(serverProvider.isLoading, isFalse);
      expect(serverProvider.error, isNull);
    });

    test('loadServers should set error on failure', () async {
      // Arrange
      when(() => mockApiService.getServers())
          .thenThrow(Exception('Failed to load servers'));

      // Act
      await serverProvider.loadServers();

      // Assert
      expect(serverProvider.servers, isEmpty);
      expect(serverProvider.isLoading, isFalse);
      expect(serverProvider.error, isNotNull);
    });
  });

  group('ServerProvider - Server Operations', () {
    test('addServer should add server on success', () async {
      // Arrange
      const mockServer = Server(
        id: '1',
        name: 'New Server',
        hostname: 'new.example.com',
        type: ServerType.linux,
        category: ServerCategory.physical,
        status: ServerStatus.online,
        resources: ResourceUsage(
          cpu: 0.0,
          memory: 0.0,
          disk: 0.0,
          network: "0 MB/s",
          history: [],
          lastUpdated: null,
        ),
        uptime: "0s",
        processes: [],
        recentLogs: [],
      );

      when(() => mockApiService.testServerConnection(
            host: any(named: 'host'),
            port: any(named: 'port'),
            username: any(named: 'username'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => true);

      when(() => mockApiService.addServer(
            name: any(named: 'name'),
            host: any(named: 'host'),
            port: any(named: 'port'),
            username: any(named: 'username'),
            password: any(named: 'password'),
            type: any(named: 'type'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => mockServer);

      // Act
      await serverProvider.addServer(
        name: 'New Server',
        host: 'new.example.com',
        port: 22,
        username: 'admin',
        password: 'password',
        type: ServerType.linux,
        category: ServerCategory.physical,
      );

      // Assert
      expect(serverProvider.servers, contains(mockServer));
      expect(serverProvider.isLoading, isFalse);
      expect(serverProvider.error, isNull);
    });

    test('deleteServer should remove server on success', () async {
      // Arrange
      const mockServer = Server(
        id: '1',
        name: 'Test Server',
        hostname: 'test.example.com',
        type: ServerType.linux,
        category: ServerCategory.physical,
        status: ServerStatus.online,
        resources: ResourceUsage(
          cpu: 0.0,
          memory: 0.0,
          disk: 0.0,
          network: "0 MB/s",
          history: [],
          lastUpdated: null,
        ),
        uptime: "0s",
        processes: [],
        recentLogs: [],
      );

      when(() => mockApiService.deleteServer(any()))
          .thenAnswer((_) async => {});

      // Act
      serverProvider.servers.add(mockServer);
      await serverProvider.deleteServer(mockServer.id);

      // Assert
      expect(serverProvider.servers, isEmpty);
      expect(serverProvider.isLoading, isFalse);
      expect(serverProvider.error, isNull);
    });
  });

  group('ServerProvider - Server Monitoring', () {
    test('startMonitoring should subscribe to server metrics', () async {
      // Arrange
      const serverId = '1';

      // Act
      serverProvider.startMonitoring(serverId);

      // Assert
      verify(() => mockWebSocketService.subscribeToServerMetrics(serverId))
          .called(1);
    });

    test('stopMonitoring should unsubscribe from server metrics', () {
      // Arrange
      const serverId = '1';
      serverProvider.startMonitoring(serverId);

      // Act
      serverProvider.stopMonitoring(serverId);

      // Assert
      verify(() => mockWebSocketService.unsubscribeFromServerMetrics(serverId))
          .called(1);
    });
  });
}
