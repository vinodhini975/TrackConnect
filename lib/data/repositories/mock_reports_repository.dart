import '../models/eco_report.dart';
import '../models/app_notification.dart';
import '../mock_data/mock_data_store.dart';
import 'reports_repository.dart';

class MockReportsRepository implements ReportsRepository {
  @override
  Future<EcoReport> getEcoReport(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockDataStore.report;
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      AppNotification(
        id: 'notif_1', title: 'Truck Arriving Soon',
        message: 'Truck KA-01-2345 is 5 minutes away.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false, type: 'TRUCK_ARRIVING',
      ),
      AppNotification(
        id: 'notif_2', title: 'Collection Completed',
        message: 'Organic waste collected from Ward 195.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true, type: 'COLLECTION',
      ),
    ];
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {}
}
