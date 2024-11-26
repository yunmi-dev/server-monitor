// lib/models/usage_data.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:math';

@immutable
class UsageData {
  final String timestamp;
  final List<double> values;
  final DateTime dateTime;

  UsageData({
    required this.timestamp,
    required this.values,
    DateTime? dateTime,
  }) : dateTime = dateTime ?? DateTime.now();

  factory UsageData.fromJson(Map<String, dynamic> json) {
    final valuesList = json['values'] as List;
    final values = valuesList.map((v) => (v as num).toDouble()).toList();

    return UsageData(
      timestamp: json['timestamp'] as String,
      values: values,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'values': values,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  UsageData copyWith({
    String? timestamp,
    List<double>? values,
    DateTime? dateTime,
  }) {
    return UsageData(
      timestamp: timestamp ?? this.timestamp,
      values: values ?? this.values,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  static List<UsageData> generateSampleData() {
    final now = DateTime.now();
    final formatter = DateFormat('HH:mm');
    final random = Random();

    return List.generate(12, (index) {
      final time = now.subtract(Duration(hours: 11 - index));
      return UsageData(
        timestamp: formatter.format(time),
        values: [
          60 + random.nextDouble() * 30, // CPU
          50 + random.nextDouble() * 20, // Memory
          30 + random.nextDouble() * 40, // Network
        ],
        dateTime: time,
      );
    });
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageData &&
        other.timestamp == timestamp &&
        listEquals(other.values, values) &&
        other.dateTime == dateTime;
  }

  @override
  int get hashCode => Object.hash(timestamp, Object.hashAll(values), dateTime);

  @override
  String toString() =>
      'UsageData(timestamp: $timestamp, values: $values, dateTime: $dateTime)';
}
