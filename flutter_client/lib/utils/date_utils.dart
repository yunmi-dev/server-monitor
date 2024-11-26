// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

class DateTimeUtils {
  static final _fullDateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _dateFormatter = DateFormat('yyyy-MM-dd');
  static final _timeFormatter = DateFormat('HH:mm:ss');
  static final _shortTimeFormatter = DateFormat('HH:mm');
  static final _monthDayFormatter = DateFormat('MM-dd');
  static final _relativeDateFormatter = DateFormat('MM-dd HH:mm');

  static String formatFull(DateTime dateTime) {
    return _fullDateFormatter.format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormatter.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormatter.format(dateTime);
  }

  static String formatShortTime(DateTime dateTime) {
    return _shortTimeFormatter.format(dateTime);
  }

  static String formatMonthDay(DateTime dateTime) {
    return _monthDayFormatter.format(dateTime);
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return _relativeDateFormatter.format(dateTime);
    }
  }

  static String formatUptime(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      23,
      59,
      59,
      999,
    );
  }
}
