// lib/services/websocket_service.dart
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_client/config/constants.dart';
import 'package:flutter_client/models/socket_message.dart';
import 'package:flutter_client/utils/logger.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  static WebSocketService get instance => _instance;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  final _messageController = StreamController<SocketMessage>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final Set<String> _subscribedServers = {}; // 구독 중인 서버 ID 추적

  WebSocketService._internal();

  bool get isConnected => _isConnected;
  Stream<SocketMessage> get messageStream => _messageController.stream;

  // 서버 메트릭스 구독 메서드 추가
  void subscribeToServerMetrics(String serverId) {
    if (_subscribedServers.contains(serverId)) return;

    sendMessage('subscribe', {
      'topic': 'server.metrics',
      'serverId': serverId,
    });
    _subscribedServers.add(serverId);
    logger.info('Subscribed to metrics for server: $serverId');
  }

  // 서버 메트릭스 구독 취소 메서드 추가
  void unsubscribeFromServerMetrics(String serverId) {
    if (!_subscribedServers.contains(serverId)) return;

    sendMessage('unsubscribe', {
      'topic': 'server.metrics',
      'serverId': serverId,
    });
    _subscribedServers.remove(serverId);
    logger.info('Unsubscribed from metrics for server: $serverId');
  }

  // 재연결 시 모든 구독 복구
  void _restoreSubscriptions() {
    for (final serverId in _subscribedServers) {
      subscribeToServerMetrics(serverId);
    }
  }

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(AppConstants.wsUrl),
      );
      _isConnected = true;

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: true,
      );

      _startPingTimer();
      _restoreSubscriptions(); // 연결 후 구독 복구
      logger.info('WebSocket connected');
    } catch (e) {
      logger.error('WebSocket connection failed: $e');
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final socketMessage = SocketMessage.fromJson(message);
      _messageController.add(socketMessage);
    } catch (e) {
      logger.error('Failed to parse WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    logger.error('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    logger.info('WebSocket disconnected');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      connect,
    );
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

      _channel?.sink.add(message.toJson());
      logger.debug('Sent WebSocket message: ${message.toJson()}');
    } catch (e) {
      logger.error('Failed to send WebSocket message: $e');
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscribedServers.clear(); // 구독 목록 초기화
    await _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
