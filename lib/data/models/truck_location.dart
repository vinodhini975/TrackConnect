import 'package:cloud_firestore/cloud_firestore.dart';

class TruckLocation {
  final String truckId;
  final String truckNumber;
  final String driverName;
  final double latitude;
  final double longitude;
  final String currentAddress;
  final String headingToWard;
  final int etaMinutes;
  final bool isActive;
  final DateTime lastUpdated;

  const TruckLocation({
    required this.truckId,
    required this.truckNumber,
    required this.driverName,
    required this.latitude,
    required this.longitude,
    required this.currentAddress,
    required this.headingToWard,
    required this.etaMinutes,
    required this.isActive,
    required this.lastUpdated,
  });

  factory TruckLocation.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    
    // Support status string from your screenshot
    bool active = false;
    if (map['status'] != null) {
      active = map['status'].toString().toLowerCase() == 'active';
    } else if (map['isActive'] != null) {
      active = map['isActive'] == true;
    }

    return TruckLocation(
      truckId: doc.id,
      truckNumber: map['vehicleId'] ?? 'Unknown',
      driverName: map['name'] ?? 'Driver',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      currentAddress: map['zone'] ?? map['currentAddress'] ?? 'Tracking...',
      headingToWard: (map['ward'] ?? '').toString(),
      etaMinutes: 5, // Default for demo
      isActive: active,
      lastUpdated: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
