// lib/features/notifications/notification_provider.dart

import 'package:flutter/material.dart';
import 'widgets/notification_item.dart';
import 'models/notification_models.dart';

class NotificationProvider extends ChangeNotifier {
  List<ServerNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<ServerNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 임시 데이터
      await Future.delayed(const Duration(seconds: 1));
      _notifications = [
        ServerNotification(
          id: '1',
          title: 'High CPU Usage',
          message: 'Production Server CPU usage is at 92%',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          type: NotificationType.error,
          serverId: 'server-1',
        ),
        ServerNotification(
          id: '2',
          title: 'Memory Warning',
          message: 'Development Server memory usage is high',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          type: NotificationType.warning,
          serverId: 'server-2',
        ),
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
