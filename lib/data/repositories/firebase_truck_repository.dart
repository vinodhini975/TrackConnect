import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/truck_location.dart';
import 'truck_repository.dart';

class FirebaseTruckRepository implements TruckRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<TruckLocation?> getTruckStream(String wardNumber) {
    debugPrint("🚚 TruckRepo: User ward is '$wardNumber'");

    return _db
        .collection('drivers')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      // Normalize user ward (e.g., "Ward 195" -> "195")
      final cleanUserWard = wardNumber.replaceAll(RegExp(r'[^0-9]'), '').trim();

      try {
        final matchingDoc = snapshot.docs.firstWhere((doc) {
          final data = doc.data();
          
          // 1. Check if active
          final status = data['status']?.toString().toLowerCase() ?? '';
          final isActive = status == 'active';
          
          // 2. Check if ward matches (normalize "195" vs "195")
          final driverWard = (data['ward'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
          
          return isActive && driverWard == cleanUserWard;
        });

        debugPrint("✅ TruckRepo: Match found for ward $cleanUserWard!");
        return TruckLocation.fromFirestore(matchingDoc);
      } catch (e) {
        debugPrint("ℹ️ TruckRepo: No active drivers currently in ward $cleanUserWard");
        return null;
      }
    });
  }

  @override
  Future<void> reportMissedCollection(String wardNumber, String userId) async {
    await _db.collection('complaints').add({
      'userId': userId,
      'wardNumber': wardNumber,
      'type': 'MISSED_COLLECTION',
      'status': 'PENDING',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
