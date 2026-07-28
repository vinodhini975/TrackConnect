import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eco_report.dart';
import '../models/app_notification.dart';
import 'reports_repository.dart';

class FirebaseReportsRepository implements ReportsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<EcoReport> getEcoReport(String userId) async {
    final doc = await _db.collection('reports').doc(userId).get();
    if (!doc.exists) {
      return EcoReport(
        userId: userId,
        totalEcoPoints: 0,
        level: 'Eco Beginner',
        wasteSavedKg: 0,
        co2SavedKg: 0,
        recycledKg: 0,
        treesEquivalent: 0,
        weeklyConsistency: [false, false, false, false, false, false, false],
      );
    }
    return EcoReport.fromFirestore(doc);
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    // Simplified query: Removed 'orderBy' to avoid mandatory composite index
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    
    final notifications = snapshot.docs.map((doc) {
      final map = doc.data();
      return AppNotification(
        id: doc.id,
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        isRead: map['isRead'] ?? false,
        type: map['type'] ?? 'INFO',
      );
    }).toList();

    // Sort in memory instead
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }
}
