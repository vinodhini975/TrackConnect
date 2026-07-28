import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_schedule.dart';
import 'schedule_repository.dart';

class FirebaseScheduleRepository implements ScheduleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<CollectionSchedule>> getWeeklySchedule(String wardNumber) async {
    final snapshot = await _db
        .collection('schedules')
        .where('wardNumber', isEqualTo: wardNumber)
        .get();
    
    return snapshot.docs.map((doc) => CollectionSchedule.fromFirestore(doc)).toList();
  }

  @override
  Future<CollectionSchedule?> getNextCollection(String wardNumber) async {
    // Simplified query to avoid mandatory composite index
    final snapshot = await _db
        .collection('schedules')
        .where('wardNumber', isEqualTo: wardNumber)
        .get();
    
    if (snapshot.docs.isEmpty) return null;

    // Filter "No Collection" in memory
    final validSchedules = snapshot.docs
        .map((doc) => CollectionSchedule.fromFirestore(doc))
        .where((s) => s.wasteType != 'No Collection')
        .toList();

    return validSchedules.isNotEmpty ? validSchedules.first : null;
  }

  @override
  Future<void> toggleReminder(String scheduleId, bool enabled) async {
    await _db.collection('schedules').doc(scheduleId).update({
      'reminderEnabled': enabled,
    });
  }
}
