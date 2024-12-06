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
  final _metricsController = StreamController<ServerMetrics>.broadcast(); // 추가
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
  Stream<ServerMetrics> get metricsStream => _metricsController.stream;

  void _handleMessage(dynamic message) {
    try {
      logger.verbose('Processing incoming WebSocket message...');

      Map<String, dynamic> data;
      if (message is String) {
        data = jsonDecode(message);
      } else if (message is Map<String, dynamic>) {
        data = message;
      } else {
        throw const FormatException('Invalid message format');
      }

      // 서버 메트릭 데이터 처리
      if (data.containsKey('data') &&
          data['data'] is Map<String, dynamic> &&
          data['data'].containsKey('cpuUsage')) {
        try {
          final metricData = data['data'];
          logger.verbose('Processing server metrics data: $metricData');

          final metrics = ServerMetrics(
            serverId: metricData['serverId'] as String,
            cpuUsage: (metricData['cpuUsage'] as num).toDouble(),
            memoryUsage: (metricData['memoryUsage'] as num).toDouble(),
            diskUsage: (metricData['diskUsage'] as num).toDouble(),
            networkUsage: (metricData['networkUsage'] as num).toDouble(),
            processCount: metricData['processCount'] as int,
            timestamp: DateTime.parse(metricData['timestamp'] as String),
            processes: (metricData['processes'] as List<dynamic>)
                .map((p) => ProcessInfo(
                      pid: p['pid'] as int,
                      name: p['name'] as String,
                      cpuUsage: (p['cpuUsage'] as num).toDouble(),
                      memoryUsage: (p['memoryUsage'] as num).toDouble(),
                    ))
                .toList(),
          );

          final socketMessage = SocketMessage(
            type: MessageType.resourceMetrics,
            data: data['data'],
            timestamp: metrics.timestamp,
          );

          _messageController.add(socketMessage);
          _metricsController.add(metrics);

          logger.info(
              'Successfully processed metrics for server: ${metrics.serverId}');
          logger.verbose(
              'CPU: ${metrics.cpuUsage}%, Memory: ${metrics.memoryUsage}%, Disk: ${metrics.diskUsage}%, Network: ${metrics.networkUsage}');
        } catch (e, stack) {
          logger.error('Failed to parse metrics data: $e');
          logger.error('Stack trace: $stack');
          logger.error('Raw metric data: ${data['data']}');
        }
      } else {
        logger.verbose('Processing non-metrics message');
        final socketMessage = SocketMessage.fromJson(data);
        _messageController.add(socketMessage);
        logger.info('Processed message of type: ${socketMessage.type}');
      }
    } catch (e, stack) {
      logger.error('Failed to parse WebSocket message: $e');
      logger.error('Stack trace: $stack');
      logger.error('Raw message: $message');
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
      _reconnectAttempts = 0;
      logger.info('WebSocket connected successfully');
    } catch (e) {
      _isConnecting = false;
      logger.error('WebSocket connection error: $e');
      _handleError(e);
    }
  }

  // dispose 메서드 수정
  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _metricsController.close(); // 추가
  }

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

      final wsUri = Uri.parse(AppConstants.wsUrl)
          .replace(scheme: 'ws', path: '/api/v1/ws');

      _channel = IOWebSocketChannel.connect(wsUri);

      await _channel!.ready;
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
}
