// lib/utils/number_utils.dart
import 'package:intl/intl.dart';
import 'dart:math';

class NumberUtils {
  static final _numberFormat = NumberFormat('#,##0.##');
  static final _percentFormat = NumberFormat.percentPattern();
  static final _compactFormat = NumberFormat.compact();
  static final _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String formatNumber(num value) {
    return _numberFormat.format(value);
  }

  static String formatPercent(double value) {
    return _percentFormat.format(value / 100);
  }

  static String formatCompact(num value) {
    return _compactFormat.format(value);
  }

  static String formatCurrency(num value) {
    return _currencyFormat.format(value);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static String formatBandwidth(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
    }
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
  }

  static double calculatePercentage(num value, num total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  static double roundToDecimal(double value, int places) {
    num mod = pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }

  /// 데이터 전송률 문자열을 파싱하고 포맷팅
  static String formatDataRate(String rate) {
    if (rate.isEmpty) return '0 B/s';

    try {
      // Extract number and unit from string like "1.2 MB/s"
      final RegExp regex = RegExp(r'(\d+\.?\d*)\s*([KMGT]?B)/s');
      final match = regex.firstMatch(rate);
      if (match == null) {
        // Try parsing as pure number (bytes per second)
        final number = double.tryParse(rate);
        if (number != null) {
          return formatBandwidth(number);
        }
        return rate;
      }

      final value = double.parse(match.group(1)!);
      final unit = match.group(2)!;

      // Convert to bytes based on unit
      double bytes =
          value * pow(1024, 'BKMGT'.indexOf(unit[0] == 'B' ? 'B' : unit[0]));
      return formatBandwidth(bytes);
    } catch (e) {
      return rate;
    }
  }

  /// 리소스 사용량에 대한 알기 쉬운 설명 생성
  static String getResourceDescription(String metric, double value) {
    String severity;
    if (value >= 90) {
      severity = '심각';
    } else if (value >= 75) {
      severity = '경고';
    } else if (value >= 60) {
      severity = '주의';
    } else {
      severity = '정상';
    }

    return '$metric 사용량: ${formatPercent(value)} ($severity)';
  }

  /// 서버 가동 시간을 알기 쉽게 포맷팅
  static String formatUptime(Duration uptime) {
    if (uptime.inDays > 0) {
      return '${uptime.inDays}일 ${uptime.inHours.remainder(24)}시간';
    } else if (uptime.inHours > 0) {
      return '${uptime.inHours}시간 ${uptime.inMinutes.remainder(60)}분';
    } else if (uptime.inMinutes > 0) {
      return '${uptime.inMinutes}분';
    } else {
      return '${uptime.inSeconds}초';
    }
  }

  /// 리소스 변화율 계산 및 포맷팅
  static String formatResourceTrend(double current, double previous) {
    double change = current - previous;
    String direction = change > 0 ? '↑' : '↓';
    return '$direction ${formatPercent(change.abs())}';
  }

  /// 시스템 리소스 상태 메시지 생성
  static String getSystemHealthMessage({
    required double cpu,
    required double memory,
    required double disk,
  }) {
    List<String> warnings = [];

    if (cpu >= 90) {
      warnings.add('CPU 사용량 매우 높음');
    } else if (cpu >= 75) {
      warnings.add('CPU 사용량 높음');
    }

    if (memory >= 90) {
      warnings.add('메모리 사용량 매우 높음');
    } else if (memory >= 75) {
      warnings.add('메모리 사용량 높음');
    }

    if (disk >= 90) {
      warnings.add('디스크 공간 매우 부족');
    } else if (disk >= 75) {
      warnings.add('디스크 공간 부족');
    }

    if (warnings.isEmpty) {
      return '시스템 정상';
    }
    return warnings.join(', ');
  }

  /// 네트워크 대역폭 사용률 계산
  static double calculateBandwidthUtilization(
    double currentBandwidth,
    double maxBandwidth,
  ) {
    if (maxBandwidth <= 0) return 0;
    return min((currentBandwidth / maxBandwidth) * 100, 100);
  }

  // Overloaded formatDuration for string input
  static String formatDurationFromString(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length != 3) return duration;

      return formatDuration(Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
      ));
    } catch (e) {
      return duration;
    }
  }

  // 네트워크 사용량 문자열을 바이트 단위의 숫자로 변환
  static double parseNetworkValue(String network) {
    try {
      // 숫자와 단위 추출 (예: "1.5 KB/s" -> ["1.5", "KB"])
      final RegExp regex = RegExp(r'(\d+\.?\d*)\s*([KMGT]?B)/s');
      final match = regex.firstMatch(network);

      if (match == null) {
        // 순수 숫자인 경우 그대로 반환
        return double.tryParse(network.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;
      }

      final value = double.parse(match.group(1)!);
      final unit = match.group(2)!;

      // 단위에 따른 변환
      switch (unit[0]) {
        case 'K':
          return value * 1024;
        case 'M':
          return value * 1024 * 1024;
        case 'G':
          return value * 1024 * 1024 * 1024;
        case 'T':
          return value * 1024 * 1024 * 1024 * 1024;
        default:
          return value; // B 단위 또는 단위 없는 경우
      }
    } catch (e) {
      return 0.0; // 파싱 실패시 0 반환
    }
  }
}
