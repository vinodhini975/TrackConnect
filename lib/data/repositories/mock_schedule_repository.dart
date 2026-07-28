import '../models/collection_schedule.dart';
import '../mock_data/mock_data_store.dart';
import 'schedule_repository.dart';

class MockScheduleRepository implements ScheduleRepository {
  final List<CollectionSchedule> _schedules =
    List.from(MockDataStore.ward195Schedule);

  @override
  Future<List<CollectionSchedule>> getWeeklySchedule(String wardNumber) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _schedules;
  }

  @override
  Future<CollectionSchedule?> getNextCollection(String wardNumber) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    for (int i = 0; i < 7; i++) {
      final idx = (today - 1 + i) % 7;
      final schedule = _schedules[idx];
      if (schedule.wasteType != 'No Collection') return schedule;
    }
    return null;
  }

  @override
  Future<void> toggleReminder(String scheduleId, bool enabled) async {
    final idx = _schedules.indexWhere((s) => s.id == scheduleId);
    if (idx != -1) {
      _schedules[idx] = _schedules[idx].copyWith(reminderEnabled: enabled);
    }
  }
}
