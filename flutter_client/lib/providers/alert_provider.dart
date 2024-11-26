// lib/providers/alert_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_client/models/alert.dart';
import 'package:flutter_client/services/api_service.dart';

class AlertProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Alert> _alerts = [];
  bool _loading = false;
  String? _error;
  Set<String> _selectedCategories = {};

  AlertProvider(this._apiService);

  bool get loading => _loading;
  List<Alert> get alerts => _alerts;
  String? get error => _error;
  Set<String> get selectedCategories => _selectedCategories;

  Future<void> loadAlerts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final alerts = await _apiService.getAlerts();
      _alerts = alerts.where((alert) {
        if (_selectedCategories.isEmpty) return true;
        return alert.category != null &&
            _selectedCategories.contains(alert.category);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setCategories(Set<String> categories) {
    _selectedCategories = categories;
    loadAlerts();
  }

  Future<void> deleteAlert(String id) async {
    try {
      await _apiService.deleteAlert(id);
      _alerts.removeWhere((alert) => alert.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(List<String> ids) async {
    try {
      await _apiService.markAlertsAsRead(ids);
      _alerts = _alerts.map((alert) {
        if (ids.contains(alert.id)) {
          return alert.copyWith(isRead: true);
        }
        return alert;
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
