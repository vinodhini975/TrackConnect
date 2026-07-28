import 'package:cloud_firestore/cloud_firestore.dart';

class RouteStop {
  final String area;
  final String time;
  final double latitude;
  final double longitude;

  RouteStop({
    required this.area,
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      area: map['area'] ?? "",
      time: map['time'] ?? "",
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final String ward; // Changed to String to match MapScreen logic
  final int wardNumber;
  final GeoPoint currentLocation;
  final List<RouteStop> route;
  final int currentStopIndex;
  final bool isActive;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.ward,
    required this.wardNumber,
    required this.currentLocation,
    required this.route,
    this.currentStopIndex = 0,
    this.isActive = true,
  });

  factory Driver.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Driver(
      id: doc.id,
      name: data['name'] ?? "",
      phoneNumber: data['phoneNumber'] ?? "",
      ward: data['ward']?.toString() ?? "195",
      wardNumber: data['wardNumber'] ?? 195,
      currentLocation: data['currentLocation'] ?? const GeoPoint(12.9716, 77.5946),
      route: (data['route'] as List? ?? [])
          .map((stop) => RouteStop.fromMap(stop as Map<String, dynamic>))
          .toList(),
      currentStopIndex: data['currentStopIndex'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'ward': ward,
      'wardNumber': wardNumber,
      'currentLocation': currentLocation,
      'route': route.map((stop) => stop.toMap()).toList(),
      'currentStopIndex': currentStopIndex,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
