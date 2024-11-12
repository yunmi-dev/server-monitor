// lib/shared/models/server.dart

import 'server_metrics.dart';

class Server {
  final String id;
  final String name;
  final bool isOnline;
  final String type;
  final String location;
  final ServerMetrics metrics;

  const Server({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.type,
    required this.location,
    required this.metrics,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'],
      name: json['name'],
      isOnline: json['isOnline'],
      type: json['type'],
      location: json['location'],
      metrics: ServerMetrics.fromJson(json['metrics']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isOnline': isOnline,
        'type': type,
        'location': location,
        'metrics': metrics.toJson(),
      };
}
