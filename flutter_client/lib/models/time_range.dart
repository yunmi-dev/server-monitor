// lib/models/time_range.dart
enum TimeRange {
  hour('1H', Duration(hours: 1)),
  day('1D', Duration(days: 1)),
  week('1W', Duration(days: 7)),
  month('1M', Duration(days: 30));

  final String label;
  final Duration duration;

  const TimeRange(this.label, this.duration);

  DateTime get startTime => DateTime.now().subtract(duration);
  DateTime get endTime => DateTime.now();

  static TimeRange fromDuration(Duration duration) {
    return TimeRange.values.firstWhere(
      (range) => range.duration == duration,
      orElse: () => TimeRange.hour,
    );
  }
}
