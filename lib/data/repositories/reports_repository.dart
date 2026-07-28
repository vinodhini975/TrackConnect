import '../models/eco_report.dart';
import '../models/app_notification.dart';

abstract class ReportsRepository {
  Future<EcoReport> getEcoReport(String userId);
  Future<List<AppNotification>> getNotifications(String userId);
  Future<void> markNotificationRead(String notificationId);
}
