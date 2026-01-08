import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  StreamSubscription? _truckSubscription;
  StreamSubscription? _userPosSubscription;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startUserLiveTracking();
      _listenToTruckFirestore();
      _getRoute();
    });
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
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final newTruckPos = LatLng(
            (data['latitude'] ?? 0.0).toDouble(),
            (data['longitude'] ?? 0.0).toDouble(),
          );
          if (mounted) {
            setState(() {
              _truckLocation = newTruckPos;
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
                infoWindow: const InfoWindow(title: "Waste Truck #402"),
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
                        Text("Truck #402 • $distanceText away", style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600)),
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
}