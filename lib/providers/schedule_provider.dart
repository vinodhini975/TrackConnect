import 'package:flutter/material.dart';
import '../data/models/collection_schedule.dart';
import '../data/repositories/schedule_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repo;
  List<CollectionSchedule> _schedule = [];
  CollectionSchedule? _nextCollection;
  bool _isLoading = false;

  List<CollectionSchedule> get schedule => _schedule;
  CollectionSchedule? get nextCollection => _nextCollection;
  bool get isLoading => _isLoading;

  ScheduleProvider(this._repo);

  Future<void> loadSchedule(String wardNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      _schedule = await _repo.getWeeklySchedule(wardNumber);
      _nextCollection = await _repo.getNextCollection(wardNumber);
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleReminder(String scheduleId, bool enabled) async {
    await _repo.toggleReminder(scheduleId, enabled);
    final idx = _schedule.indexWhere((s) => s.id == scheduleId);
    if (idx != -1) {
      _schedule[idx] = _schedule[idx].copyWith(reminderEnabled: enabled);
      notifyListeners();
    }
  }
}
