import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  final Position userLocation;

  const MapScreen({super.key, required this.userLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  late LatLng _userLocation;
  LatLng _truckLocation = const LatLng(13.960178, 75.510884);
  String _truckName = "Waste Truck"; // State variable for truck name
  StreamSubscription? _truckSubscription;
  StreamSubscription? _userPosSubscription;
  String _userWard = "Default"; // Placeholder for user's ward

  // Tracking State
  String? _lockedDriverId; 
  static const double kEnterRadius = 2000.0;
  static const double kExitRadius = 2500.0;

  final double geofenceRadius = 500; // meters
  bool isTruckInsideGeofence = false;

  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];

  // Grey/Uber-like Map Style
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#c9c9c9"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _userLocation = LatLng(widget.userLocation.latitude, widget.userLocation.longitude);
    _fetchUserWard();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startUserLiveTracking();
      _listenToTruckFirestore();
      _getRoute();
    });
  }

  Future<void> _fetchUserWard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey('ward')) {
          if (mounted) setState(() => _userWard = doc.data()!['ward']);
        }
      } catch (e) {
        debugPrint("Error fetching user ward: $e");
      }
    }
  }

  void _startUserLiveTracking() {
    _userPosSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _userLocation = newPosition;
        });
        _getRoute();
      }
    });
  }

  void _listenToTruckFirestore() {
    _truckSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .snapshots()
        .listen((snapshot) {
      
      Map<String, dynamic>? activeDriverData;

      try {
        // STEP 1: GATEKEEPER (Filter by Profile Ward Only)
        final wardDocs = snapshot.docs.where((doc) {
           final d = doc.data();
           final dWard = d['ward']?.toString() ?? "Default";
           return dWard == _userWard;
        }).toList();

        // STEP 2: TRACKER (Lock-on Logic)

        if (_lockedDriverId != null) {
           final lockedDoc = wardDocs.where((d) => d.id == _lockedDriverId).firstOrNull;
           if (lockedDoc != null) {
              final data = lockedDoc.data();
              bool isActive = false;
              if (data.containsKey('dutySession') && data['dutySession'] is Map) {
                 isActive = data['dutySession']['isActive'] ?? false;
              }
              
              double dLat = 0.0, dLng = 0.0;
               if (data.containsKey('currentLocation') && data['currentLocation'] is Map) {
                  final loc = data['currentLocation'] as Map<String, dynamic>;
                  dLat = (loc['latitude'] ?? 0.0).toDouble();
                  dLng = (loc['longitude'] ?? 0.0).toDouble();
               } else {
                  dLat = (data['latitude'] ?? 0.0).toDouble();
                  dLng = (data['longitude'] ?? 0.0).toDouble();
               }

              double dist = Geolocator.distanceBetween(
                 _userLocation.latitude, _userLocation.longitude, dLat, dLng);

              if (!isActive || dist > kExitRadius) {
                 // Release
                 if (mounted) setState(() => _lockedDriverId = null);
              } else {
                 // Keep
                 activeDriverData = data;
              }
           } else {
              if (mounted) setState(() => _lockedDriverId = null);
           }
        }

        if (_lockedDriverId == null) {
           double minDistance = double.infinity;
           Map<String, dynamic>? closestDriver;
           String? closestId;

           for (var doc in wardDocs) {
              final data = doc.data();
              bool isActive = false;
              if (data.containsKey('dutySession') && data['dutySession'] is Map) {
                 isActive = data['dutySession']['isActive'] ?? false;
              }

              if (isActive) {
                 double dLat = 0.0, dLng = 0.0;
                 if (data.containsKey('currentLocation') && data['currentLocation'] is Map) {
                    final loc = data['currentLocation'] as Map<String, dynamic>;
                    dLat = (loc['latitude'] ?? 0.0).toDouble();
                    dLng = (loc['longitude'] ?? 0.0).toDouble();
                 } else {
                    dLat = (data['latitude'] ?? 0.0).toDouble();
                    dLng = (data['longitude'] ?? 0.0).toDouble();
                 }

                 if (dLat != 0 && dLng != 0) {
                   double dist = Geolocator.distanceBetween(
                     _userLocation.latitude, _userLocation.longitude, dLat, dLng);
                   
                   if (dist < kEnterRadius && dist < minDistance) {
                     minDistance = dist;
                     closestDriver = data;
                     closestId = doc.id;
                   }
                 }
              }
           }

           if (closestDriver != null && closestId != null) {
              activeDriverData = closestDriver;
              if (mounted) setState(() => _lockedDriverId = closestId);
           }
        }

      } catch (e) {
        debugPrint("Filter error: $e");
      }

      if (activeDriverData != null) {
        final data = activeDriverData;
        double lat = 0.0;
        double lng = 0.0;

        // Check for 'currentLocation' map first (preferred structure)
        if (data.containsKey('currentLocation') && data['currentLocation'] is Map) {
          final loc = data['currentLocation'] as Map<String, dynamic>;
          lat = (loc['latitude'] ?? 0.0).toDouble();
          lng = (loc['longitude'] ?? 0.0).toDouble();
        } 
        // Fallback to root level fields
        else if (data.containsKey('latitude') && data.containsKey('longitude')) {
          lat = (data['latitude'] ?? 0.0).toDouble();
          lng = (data['longitude'] ?? 0.0).toDouble();
        }

        if (lat != 0.0 && lng != 0.0) {
          final newTruckPos = LatLng(lat, lng);
          
          // Extract name logic
          String fetchedName = "Waste Truck";
          if (data.containsKey('vehicleId')) {
             fetchedName = data['vehicleId'].toString();
          } else if (data.containsKey('name')) {
             fetchedName = data['name'].toString();
          } else if (data.containsKey('driverId')) {
             fetchedName = "Truck ${data['driverId']}";
          }

          if (mounted) {
            setState(() {
              _truckLocation = newTruckPos;
              _truckName = fetchedName;
            });
            _checkGeofence();
            _getRoute();
          }
        }
      }
    });
  }

  Future<void> _getRoute() async {
    const apiKey = 'AIzaSyDerIF4uqPd7nqWta1wP_6pCIRVDdXQ6VQ'; 
    try {
      String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${_userLocation.latitude},${_userLocation.longitude}&destination=${_truckLocation.latitude},${_truckLocation.longitude}&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final points = json['routes'][0]['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result = polylinePoints.decodePolyline(points);
          polylineCoordinates.clear();
          for (var point in result) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
          if (mounted) {
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  color: Colors.black,
                  width: 4,
                ),
              };
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
  }

  void _checkGeofence() {
    double distance = Geolocator.distanceBetween(
      _userLocation.latitude, _userLocation.longitude,
      _truckLocation.latitude, _truckLocation.longitude,
    );
    if (distance <= geofenceRadius && !isTruckInsideGeofence) {
      isTruckInsideGeofence = true;
      _showNotification("🚛 Truck has entered your area!");
    } else if (distance > geofenceRadius && isTruckInsideGeofence) {
      isTruckInsideGeofence = false;
      _showNotification("🚛 Truck has left your area.");
    }
  }

  void _showNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
    }
  }

  Future<double> _getDistance() async {
    return Geolocator.distanceBetween(
      _userLocation.latitude, _userLocation.longitude,
      _truckLocation.latitude, _truckLocation.longitude,
    );
  }

  @override
  void dispose() {
    _truckSubscription?.cancel();
    _userPosSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _userLocation, zoom: 15),
            markers: {
              Marker(
                markerId: const MarkerId("user"),
                position: _userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: const InfoWindow(title: "Your Location"),
              ),
              Marker(
                markerId: const MarkerId("truck"),
                position: _truckLocation,
                // Using a greener marker for the truck
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), 
                infoWindow: InfoWindow(title: _truckName),
              ),
            },
            polylines: _polylines,
            circles: {
              Circle(
                circleId: const CircleId("geofence"),
                center: _userLocation, // Geofence around user
                radius: geofenceRadius,
                strokeColor: Colors.transparent,
                strokeWidth: 0,
                fillColor: const Color(0xFF00C853).withOpacity(0.1),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              controller.setMapStyle(_mapStyle);
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          Positioned(
            top: 50,
            left: 20,
            child: _buildTopHeader(),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF00C853),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Current Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("Home Address", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return FutureBuilder<double>(
      future: _getDistance(),
      builder: (context, snapshot) {
        String etaText = "LOCATING...";
        String distanceText = "";
        if (snapshot.hasData) {
          double distance = snapshot.data!;
          int minutes = (distance / 400).ceil();
          etaText = "ARRIVING IN ${minutes < 1 ? 1 : minutes} MIN";
          distanceText = distance < 1000 ? "${distance.toInt()}m" : "${(distance / 1000).toStringAsFixed(1)}km";
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.local_shipping_rounded, size: 32, color: Color(0xFF00C853)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(etaText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00C853))),
                        Text("$_truckName • $distanceText away", style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse("tel:+1234567890")),
                    icon: const Icon(Icons.call_rounded, color: Colors.black),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F2F7),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _getRoute(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Refresh Live Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  bool _isLocationNearPolyline(LatLng userPos, List<dynamic> points) {
    // Reusing the logic from TruckEtaWidget
    const double kRouteBuffer = 500.0;
    for (var p in points) {
      if (p is Map) {
        double pLat = (p['latitude'] ?? 0.0).toDouble();
        double pLng = (p['longitude'] ?? 0.0).toDouble();
        double dist = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, pLat, pLng);
        if (dist < kRouteBuffer) return true;
      } else if (p is GeoPoint) {
         double dist = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, p.latitude, p.longitude);
         if (dist < kRouteBuffer) return true;
      }
    }
    return false;
  }
}