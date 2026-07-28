import 'dart:async';
import '../models/truck_location.dart';
import '../mock_data/mock_data_store.dart';
import 'truck_repository.dart';

class MockTruckRepository implements TruckRepository {
  @override
  Stream<TruckLocation?> getTruckStream(String wardNumber) async* {
    // Simulate real-time updates every 10 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      yield MockDataStore.activeTruck;
    }
  }

  @override
  Future<void> reportMissedCollection(String wardNumber, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // No-op in mock — Firebase will write to Firestore
  }
}
