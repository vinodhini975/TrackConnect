import '../models/truck_location.dart';

abstract class TruckRepository {
  Stream<TruckLocation?> getTruckStream(String wardNumber);
  Future<void> reportMissedCollection(String wardNumber, String userId);
}
