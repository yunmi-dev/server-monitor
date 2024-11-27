// lib/extensions/log_extensions.dart
import 'package:flutter/material.dart';
import '../models/log_entry.dart';

extension LogEntryExtension on LogEntry {
  // 로그 메시지 그룹화를 위한 helper
  String get groupKey => '${level.name}_$component';

  // 로그 레벨에 따른 배경색 (카드나 리스트타일용)
  Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (level) {
      case LogLevel.info:
        return isDark ? Colors.blue.shade900 : Colors.blue.shade50;
      case LogLevel.warning:
        return isDark ? Colors.orange.shade900 : Colors.orange.shade50;
      case LogLevel.error:
        return isDark ? Colors.red.shade900 : Colors.red.shade50;
      case LogLevel.critical:
        return isDark ? Colors.purple.shade900 : Colors.purple.shade50;
    }
  }

  // 로그 중요도에 따른 우선순위
  int get priority {
    switch (level) {
      case LogLevel.critical:
        return 0;
      case LogLevel.error:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.info:
        return 3;
    }
  }

  // 태그 색상 맵핑
  Color getTagColor(BuildContext context, String tag) {
    if (tags == null || !tags!.containsKey(tag)) return Colors.grey;

    // 태그 값에 따른 색상 로직 구현
    final value = tags![tag]?.toLowerCase() ?? '';

    if (value.contains('error') || value.contains('failed')) {
      return Colors.red;
    } else if (value.contains('warning') || value.contains('delayed')) {
      return Colors.orange;
    } else if (value.contains('success') || value.contains('completed')) {
      return Colors.green;
    }

    return Colors.blue;
  }

  // 메타데이터 포맷팅
  String get formattedMetadata {
    if (metadata == null || metadata!.isEmpty) return '';

    return metadata!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  // 날짜 기반 그룹핑을 위한 키
  String get dateGroupKey {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  // 시간대별 그룹핑을 위한 키 (시간단위)
  String get hourGroupKey {
    return '${dateGroupKey}_${timestamp.hour.toString().padLeft(2, '0')}';
  }

  // 스택트레이스 포맷팅
  String? get formattedStackTrace {
    if (stackTrace == null) return null;

    final lines = stackTrace!.split('\n');
    if (lines.length <= 3) return stackTrace;

    // 처음 3줄만 표시하고 나머지는 생략
    return '${lines.take(3).join('\n')}\n...';
  }

  // 알림 우선순위 결정
  bool get shouldNotify {
    return isCritical ||
        (isError && component.toLowerCase().contains('critical')) ||
        (tags?.containsKey('priority') == true &&
            tags!['priority']?.toLowerCase() == 'high');
  }

  // 로그 메시지 요약 (긴 메시지의 경우)
  String get summaryMessage {
    if (message.length <= 100) return message;
    return '${message.substring(0, 97)}...';
  }
}

extension LogLevelExtension on LogLevel {
  // 로그 레벨 설명 텍스트
  String get description {
    switch (this) {
      case LogLevel.info:
        return '일반 정보 로그';
      case LogLevel.warning:
        return '주의가 필요한 경고';
      case LogLevel.error:
        return '오류가 발생했습니다';
      case LogLevel.critical:
        return '즉각적인 조치가 필요합니다';
    }
  }

  // 로그 레벨별 필터 태그 색상
  Color get filterChipColor {
    switch (this) {
      case LogLevel.info:
        return Colors.blue.shade100;
      case LogLevel.warning:
        return Colors.orange.shade100;
      case LogLevel.error:
        return Colors.red.shade100;
      case LogLevel.critical:
        return Colors.purple.shade100;
    }
  }
}
