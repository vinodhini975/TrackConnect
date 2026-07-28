import 'package:flutter/material.dart';
import '../data/models/eco_report.dart';
import '../data/models/app_notification.dart';
import '../data/repositories/reports_repository.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _repo;
  EcoReport? _report;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  EcoReport? get report => _report;
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  ReportsProvider(this._repo);

  Future<void> loadReports(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _report = await _repo.getEcoReport(userId);
      _notifications = await _repo.getNotifications(userId);
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String notificationId) async {
    await _repo.markNotificationRead(notificationId);
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }
}
