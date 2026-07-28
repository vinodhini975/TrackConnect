import '../models/collection_schedule.dart';

abstract class ScheduleRepository {
  Future<List<CollectionSchedule>> getWeeklySchedule(String wardNumber);
  Future<CollectionSchedule?> getNextCollection(String wardNumber);
  Future<void> toggleReminder(String scheduleId, bool enabled);
}
