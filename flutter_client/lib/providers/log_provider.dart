// lib/providers/log_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_client/models/log_entry.dart';
import 'package:flutter_client/models/log_filter.dart';
import 'package:flutter_client/services/log_service.dart';

class LogProvider extends ChangeNotifier {
  final LogService _logService;

  List<LogEntry> _logs = [];
  bool _isLoading = false;
  String? _error;
  LogFilter _currentFilter = const LogFilter();
  bool _hasMore = true;

  List<LogEntry> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LogFilter get currentFilter => _currentFilter;
  bool get hasMore => _hasMore;

  LogProvider({required LogService logService}) : _logService = logService;

  Future<void> loadLogs({LogFilter? filter}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newFilter = filter ?? _currentFilter;
      final newLogs = await _logService.getLogs(newFilter);

      if (newFilter.offset == 0) {
        _logs = newLogs;
      } else {
        _logs.addAll(newLogs);
      }

      _hasMore = newLogs.length >= newFilter.limit;
      _currentFilter = newFilter;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLogs() =>
      loadLogs(filter: _currentFilter.copyWith(offset: 0));

  Future<void> updateFilter(LogFilter filter) => loadLogs(filter: filter);

  Map<LogLevel, int> getLevelCounts() {
    final counts = <LogLevel, int>{};
    for (final log in _logs) {
      counts[log.level] = (counts[log.level] ?? 0) + 1;
    }
    return counts;
  }
}
