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

  WebSocketService._internal();

  bool get isConnected => _isConnected;
  Stream<SocketMessage> get messageStream => _messageController.stream;

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
      _channel?.sink.add('ping');
    }
  }

  void sendMessage(String type, Map<String, dynamic> data) {
    if (!_isConnected) {
      logger.warning('Attempted to send message while disconnected');
      return;
    }

    final message = SocketMessage(
      type: MessageType.values
          .firstWhere((e) => e.toString() == 'MessageType.$type'), // 일단 이렇게 수정
      data: data,
      timestamp: DateTime.now(),
    );

    _channel?.sink.add(message.toJson());
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
