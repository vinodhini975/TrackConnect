import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';

class DummyDataSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedDriversInWard195() async {
    // List of 8 dummy drivers for Bangalore Ward 195
    final List<Map<String, dynamic>> driversData = [
      {
        'id': 'driver_001',
        'name': 'Ramesh Kumar',
        'phoneNumber': '+91 98765 00001',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.9141, 77.5990),
        'route': [
          {'area': 'BTM Layout 2nd Stage', 'time': '7:00 AM', 'latitude': 12.9141, 'longitude': 77.5990},
          {'area': 'AXA Signal', 'time': '7:15 AM', 'latitude': 12.9160, 'longitude': 77.6010},
          {'area': 'Madiwala Lake', 'time': '7:30 AM', 'latitude': 12.9200, 'longitude': 77.6040},
        ],
      },
      {
        'id': 'driver_002',
        'name': 'Suresh Singh',
        'phoneNumber': '+91 98765 00002',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.9172, 77.6228),
        'route': [
          {'area': 'Silk Board', 'time': '7:00 AM', 'latitude': 12.9172, 'longitude': 77.6228},
          {'area': 'HSR Layout 5th Main', 'time': '7:20 AM', 'latitude': 12.9100, 'longitude': 77.6300},
          {'area': 'Agara Lake', 'time': '7:45 AM', 'latitude': 12.9250, 'longitude': 77.6350},
        ],
      },
      {
        'id': 'driver_003',
        'name': 'Mahesh Hegde',
        'phoneNumber': '+91 98765 00003',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.9063, 77.5857),
        'route': [
          {'area': 'Jayanagar 4th Block', 'time': '6:30 AM', 'latitude': 12.9279, 'longitude': 77.5871},
          {'area': 'Jayanagar 9th Block', 'time': '7:00 AM', 'latitude': 12.9150, 'longitude': 77.5900},
          {'area': 'JP Nagar 2nd Phase', 'time': '7:30 AM', 'latitude': 12.9063, 'longitude': 77.5857},
        ],
      },
      {
        'id': 'driver_004',
        'name': 'Manjunath Reddy',
        'phoneNumber': '+91 98765 00004',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.9304, 77.6174),
        'route': [
          {'area': 'Koramangala 4th Block', 'time': '7:00 AM', 'latitude': 12.9304, 'longitude': 77.6174},
          {'area': 'Koramangala 8th Block', 'time': '7:25 AM', 'latitude': 12.9380, 'longitude': 77.6200},
          {'area': 'Passport Office', 'time': '7:50 AM', 'latitude': 12.9450, 'longitude': 77.6250},
        ],
      },
      {
        'id': 'driver_005',
        'name': 'Prakash Raj',
        'phoneNumber': '+91 98765 00005',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.8950, 77.6000),
        'route': [
          {'area': 'Bommanahalli', 'time': '7:00 AM', 'latitude': 12.9038, 'longitude': 77.6242},
          {'area': 'Hongasandra', 'time': '7:20 AM', 'latitude': 12.9000, 'longitude': 77.6100},
          {'area': 'Devarachikkanahalli', 'time': '7:45 AM', 'latitude': 12.8950, 'longitude': 77.6000},
        ],
      },
      {
        'id': 'driver_006',
        'name': 'Lokesh Gowda',
        'phoneNumber': '+91 98765 00006',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.9200, 77.5800),
        'route': [
          {'area': 'Banashankari 2nd Stage', 'time': '7:00 AM', 'latitude': 12.9254, 'longitude': 77.5738},
          {'area': 'BSK BDA Complex', 'time': '7:25 AM', 'latitude': 12.9220, 'longitude': 77.5750},
          {'area': 'Mono Type', 'time': '7:40 AM', 'latitude': 12.9200, 'longitude': 77.5800},
        ],
      },
      {
        'id': 'driver_007',
        'name': 'Anil Deshpande',
        'phoneNumber': '+91 98765 00007',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.9000, 77.5750),
        'route': [
          {'area': 'Sarakki Junction', 'time': '7:00 AM', 'latitude': 12.9070, 'longitude': 77.5780},
          {'area': 'JP Nagar 5th Phase', 'time': '7:20 AM', 'latitude': 12.9050, 'longitude': 77.5800},
          {'area': 'Brigade Millennium', 'time': '7:40 AM', 'latitude': 12.9000, 'longitude': 77.5750},
        ],
      },
      {
        'id': 'driver_008',
        'name': 'Vijay Shelar',
        'phoneNumber': '+91 98765 00008',
        'ward': '195',
        'wardNumber': 195,
        'isActive': true,
        'currentLocation': const GeoPoint(12.8800, 77.5850),
        'route': [
          {'area': 'Konanakunte Cross', 'time': '7:00 AM', 'latitude': 12.8887, 'longitude': 77.5734},
          {'area': 'Doddakallasandra', 'time': '7:25 AM', 'latitude': 12.8850, 'longitude': 77.5800},
          {'area': 'Gubbalala', 'time': '7:45 AM', 'latitude': 12.8800, 'longitude': 77.5850},
        ],
      },
    ];

    WriteBatch batch = _db.batch();
    for (var d in driversData) {
      DocumentReference ref = _db.collection('drivers').doc(d['id']);
      batch.set(ref, {
        ...d,
        'currentStopIndex': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    print("Dummy drivers seeded successfully!");
  }
}
