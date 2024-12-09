// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/socket_message.dart';
import 'package:flutter_client/models/server_metrics.dart';
import 'package:flutter_client/utils/logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_client/services/storage_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  static WebSocketService get instance => _instance;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  final _messageController = StreamController<SocketMessage>.broadcast();
  final _metricsController = StreamController<ServerMetrics>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final Set<String> _subscribedServers = {};

  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);

  WebSocketService._internal();

  Stream<SocketMessage> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;
  Stream<ServerMetrics> get metricsStream => _metricsController.stream;

// lib/services/websocket_service.dart의 _handleMessage 함수 수정 TODO debug
  void _handleMessage(dynamic message) {
    try {
      print('WebSocket received raw message: $message'); // 로그 추가
      final data = jsonDecode(message as String);
      print('Decoded WebSocket message: $data'); // 로그 추가

      final socketMessage = SocketMessage(
        type: _getMessageType(data['type'] as String?),
        data: data['data'] as Map<String, dynamic>,
        timestamp: DateTime.now(),
      );

      print('Created SocketMessage: ${socketMessage.type}'); // 로그 추가
      _messageController.add(socketMessage);

      if (socketMessage.type == MessageType.resourceMetrics) {
        final metricData = socketMessage.data;
        print('Processing resource metrics: $metricData'); // 로그 추가

        final metrics = ServerMetrics(
          serverId: metricData['serverId'],
          cpuUsage: metricData['cpuUsage'].toDouble(),
          memoryUsage: metricData['memoryUsage'].toDouble(),
          diskUsage: metricData['diskUsage'].toDouble(),
          networkUsage: metricData['networkUsage'].toDouble(),
          processCount: metricData['processCount'],
          timestamp: DateTime.parse(metricData['timestamp']),
        );
        print('Created ServerMetrics object: ${metrics.toString()}'); // 로그 추가
        _metricsController.add(metrics);
      }
    } catch (e, stack) {
      print('WebSocket message processing error: $e'); // 로그 추가
      print('Stack trace: $stack'); // 로그 추가
      logger.error('Error processing WebSocket message: $e\n$stack');
    }
  }

  MessageType _getMessageType(String? type) {
    switch (type) {
      case 'resource_metrics': // 수정된 타입
        return MessageType.resourceMetrics;
      case 'alert':
        return MessageType.alert;
      case 'log':
        return MessageType.log;
      default:
        return MessageType.unknown;
    }
  }

  // 에러 확인용 TODO
  void connectToWebSocket() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;

    try {
      final storage = await StorageService.initialize();
      final token = await storage.getToken();

      if (token == null) {
        logger.error('WebSocket connection failed: Missing auth token');
        _handleError('No authorization token');
        _isConnecting = false;
        return;
      }

      // WebSocket URL 수정
      final wsUrl = Uri.parse('${AppConstants.wsUrl}/api/v1/ws')
          .replace(scheme: 'ws')
          .toString();
      logger.info('Connecting to WebSocket at: $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Connection': 'Upgrade',
          'Upgrade': 'websocket',
        },
      );

      _channel!.stream.listen(
        (message) {
          logger.info('Received: $message');
          _handleMessage(message);
        },
        onError: (error) {
          logger.error('WebSocket error: $error');
          _handleError(error);
        },
        onDone: () {
          logger.info('WebSocket closed');
          _handleDisconnect();
        },
      );

      _isConnected = true;
      _isConnecting = false;
      logger.info('WebSocket connected successfully');
    } catch (e) {
      _isConnecting = false;
      logger.error('WebSocket connection error: $e');
      _handleError(e);
    }
  }

  void subscribeToServerMetrics(String serverId) {
    if (!_subscribedServers.contains(serverId)) {
      final message = {
        'type': 'server_metrics.subscribe',
        'data': {'serverId': serverId}
      };

      _channel?.sink.add(jsonEncode(message));
      _subscribedServers.add(serverId);
      logger.info('Subscribed to metrics for server: $serverId');
    }
  }

  void unsubscribeFromServerMetrics(String serverId) {
    if (_subscribedServers.contains(serverId)) {
      final message = {
        'type': 'server_metrics.unsubscribe',
        'data': {'server_id': serverId}
      };

      _channel?.sink.add(jsonEncode(message));
      _subscribedServers.remove(serverId);
      logger.info('Unsubscribed from metrics for server: $serverId');
    }
  }

  void _restoreSubscriptions() {
    for (final serverId in _subscribedServers.toList()) {
      subscribeToServerMetrics(serverId);
    }
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;

    try {
      _isConnecting = true;
      logger.info('Connecting to WebSocket...');

      final storage = await StorageService.initialize();
      final token = await storage.getToken();

      if (token == null) {
        throw Exception('Missing auth token');
      }

      final wsUri = Uri.parse(AppConstants.wsUrl)
          .replace(scheme: 'ws', path: '/api/v1/ws');

      _channel = IOWebSocketChannel.connect(
        wsUri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: true,
      );

      _isConnected = true;
      _isConnecting = false;
      _startPingTimer();
      _restoreSubscriptions();
      logger.info('WebSocket connected successfully');
    } catch (e) {
      _isConnecting = false;
      logger.error('WebSocket connection failed: $e');
      _handleError(e);
    }
  }

  void _handleError(dynamic error) {
    logger.error('WebSocket error: $error');
    _isConnected = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    logger.info('WebSocket disconnected');
    _isConnected = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected && !_isConnecting) {
        connect();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }

  void _sendPing() {
    if (_isConnected) {
      final message = {
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      };
      _channel?.sink.add(jsonEncode(message));
    }
  }

  void sendMessage(String type, Map<String, dynamic> data) {
    if (!_isConnected) {
      logger.warning('Attempted to send message while disconnected');
      return;
    }

    try {
      final message = SocketMessage(
        type: MessageType.values.firstWhere(
          (e) => e.value.toLowerCase() == type.toLowerCase(),
          orElse: () => MessageType.unknown,
        ),
        data: data,
        timestamp: DateTime.now(),
      );

      final jsonString = jsonEncode(message.toJson());
      _channel?.sink.add(jsonString);

      logger.debug('Sent WebSocket message: ${message.type}');
    } catch (e) {
      logger.error('Failed to send WebSocket message: $e');
      _handleError(e);
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscribedServers.clear();

    if (_channel != null) {
      await _channel!.sink.close();
      _isConnected = false;
      _isConnecting = false;
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _metricsController.close();
    await _messageController.close();
  }
}
