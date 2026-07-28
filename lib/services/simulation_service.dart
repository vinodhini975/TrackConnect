import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';

class SimulationService {
  static Timer? _timer;
  static bool _isRunning = false;

  static void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _moveTrucks();
    });
    print("Simulation started...");
  }

  static void stopSimulation() {
    _timer?.cancel();
    _isRunning = false;
    print("Simulation stopped.");
  }

  static Future<void> _moveTrucks() async {
    try {
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('ward', isEqualTo: '195')
          .get();

      if (driversSnapshot.docs.isEmpty) return;

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in driversSnapshot.docs) {
        final driver = Driver.fromFirestore(doc);
        if (driver.route.isEmpty) continue;

        int nextIndex = (driver.currentStopIndex + 1) % driver.route.length;
        final currentPos = driver.currentLocation;
        final targetStop = driver.route[nextIndex];

        // Move 5% towards the next stop each tick
        double newLat = currentPos.latitude + (targetStop.latitude - currentPos.latitude) * 0.05;
        double newLng = currentPos.longitude + (targetStop.longitude - currentPos.longitude) * 0.05;

        // Check if arrived at stop
        double dist = (newLat - targetStop.latitude).abs() + (newLng - targetStop.longitude).abs();
        int finalNextIndex = driver.currentStopIndex;
        
        if (dist < 0.0001) {
          finalNextIndex = nextIndex;
        }

        batch.update(doc.reference, {
          'currentLocation': GeoPoint(newLat, newLng),
          'currentStopIndex': finalNextIndex,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print("Simulation Error: $e");
    }
  }
}
