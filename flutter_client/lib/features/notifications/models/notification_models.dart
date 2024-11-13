// lib/features/notifications/models/notification_models.dart

enum NotificationType {
  info,
  warning,
  error,
}

class ServerNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? serverId;
  final bool isRead;

  const ServerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = NotificationType.info,
    this.serverId,
    this.isRead = false,
  });

  // copyWith 메서드 추가
  ServerNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    String? serverId,
    bool? isRead,
  }) {
    return ServerNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      serverId: serverId ?? this.serverId,
      isRead: isRead ?? this.isRead,
    );
  }

  // 선택적: JSON 직렬화를 위한 메서드 추가
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'serverId': serverId,
      'isRead': isRead,
    };
  }

  // 선택적: JSON에서 객체 생성을 위한 팩토리 메서드 추가
  factory ServerNotification.fromJson(Map<String, dynamic> json) {
    return ServerNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.info,
      ),
      serverId: json['serverId'],
      isRead: json['isRead'] ?? false,
    );
  }
}
