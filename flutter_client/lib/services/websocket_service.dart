// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/socket_message.dart';
import 'package:flutter_client/utils/logger.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  static WebSocketService get instance => _instance;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  final _messageController = StreamController<SocketMessage>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final Set<String> _subscribedServers = {};
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration initialReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);

  WebSocketService._internal();

  bool get isConnected => _isConnected;
  Stream<SocketMessage> get messageStream => _messageController.stream;

  void subscribeToServerMetrics(String serverId) {
    if (_subscribedServers.contains(serverId)) return;

    if (_isConnected) {
      sendMessage('resource_metrics', {
        'topic': 'server.metrics',
        'serverId': serverId,
      });
      _subscribedServers.add(serverId);
      logger.info('Subscribed to metrics for server: $serverId');
    } else {
      _subscribedServers.add(serverId);
      logger.info('Queued subscription for server: $serverId');
    }
  }

  void unsubscribeFromServerMetrics(String serverId) {
    if (!_subscribedServers.contains(serverId)) return;

    if (_isConnected) {
      sendMessage('resource_metrics', {
        'topic': 'server.metrics',
        'serverId': serverId,
        'action': 'unsubscribe'
      });
    }
    _subscribedServers.remove(serverId);
    logger.info('Unsubscribed from metrics for server: $serverId');
  }

  void _restoreSubscriptions() {
    if (!_isConnected) return;

    for (final serverId in _subscribedServers.toList()) {
      sendMessage('subscribe', {
        'topic': 'server.metrics',
        'serverId': serverId,
      });
      logger.info('Restored subscription for server: $serverId');
    }
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;

    try {
      _isConnecting = true;
      logger.info('Attempting WebSocket connection...');

      _channel = WebSocketChannel.connect(
        Uri.parse(AppConstants.wsUrl),
      );

      // Add connection timeout
      bool connected = false;
      Timer(const Duration(seconds: 5), () {
        if (!connected) {
          logger.error('WebSocket connection timeout');
          _handleError('Connection timeout');
        }
      });

      await _channel!.ready;
      connected = true;
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: true,
      );

      _startPingTimer();
      _restoreSubscriptions();
      logger.info('WebSocket connected successfully');
    } catch (e) {
      _isConnecting = false;
      logger.error('WebSocket connection failed: $e');
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is String || message is Map<String, dynamic>) {
        final socketMessage = SocketMessage.fromJson(message);

        // 리소스 메트릭은 verbose 레벨로 로깅
        if (socketMessage.type == MessageType.resourceMetrics) {
          logger.verbose('Received metrics message');
        } else {
          logger.info(
              'Received WebSocket message: $socketMessage.type'); // 중괄호 제거
        }

        _messageController.add(socketMessage);
      }
    } catch (e) {
      logger.error('Failed to parse WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    logger.error('WebSocket error: $error');
    _isConnected = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    if (_isConnected) {
      logger.info('WebSocket disconnected');
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= maxReconnectAttempts) {
      logger.error('Max reconnection attempts reached');
      return;
    }

    final delay = Duration(
        seconds: (initialReconnectDelay.inSeconds * (1 << _reconnectAttempts))
            .clamp(0, maxReconnectDelay.inSeconds));

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      logger.info(
          'Attempting reconnect (${_reconnectAttempts}/$maxReconnectAttempts)');
      connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendPing(),
    );
  }

  void _sendPing() {
    if (_isConnected) {
      sendMessage('ping', {'timestamp': DateTime.now().toIso8601String()});
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
          (e) =>
              e.toString().split('.').last.toLowerCase() == type.toLowerCase(),
          orElse: () => MessageType.unknown,
        ),
        data: data,
        timestamp: DateTime.now(),
      );

      // Map을 JSON 문자열로 직렬화
      final jsonString = jsonEncode(message.toJson());
      _channel?.sink.add(jsonString);

      logger.debug('Sent WebSocket message: $message.type'); // 중괄호 제거
    } catch (e) {
      logger.error('Failed to send WebSocket message: $e');
      _handleError(e);
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscribedServers.clear();
    _reconnectAttempts = 0;
    _isConnecting = false;

    if (_channel != null) {
      try {
        await _channel!.sink.close();
        logger.info('WebSocket disconnected cleanly');
      } catch (e) {
        logger.error('Error during WebSocket disconnect: $e');
      }
    }

    _isConnected = false;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
  }
}
