import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// ✅ This is your correct file name: `map_screen.dart`
/// ✅ This is your correct widget class name: `MapScreen`

class MapScreen extends StatefulWidget {
  final Position userLocation;

  const MapScreen({super.key, required this.userLocation}); // ✅ Add `key`


  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  late LatLng _userLocation;
  LatLng _truckLocation = const LatLng(13.960178, 75.510884);

  final double geofenceRadius = 500; // meters
  bool isTruckInsideGeofence = false;

  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];

  @override
  void initState() {
    super.initState();
    _userLocation = LatLng(widget.userLocation.latitude, widget.userLocation.longitude);

    _startUserLiveTracking();
    _simulateTruckMovement();
    _getRoute(); // Get real route at start
  }

  void _startUserLiveTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(_userLocation));

      _getRoute(); // Update route when user moves
    });
  }

  void _simulateTruckMovement() {
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _truckLocation = LatLng(
          _truckLocation.latitude + 0.0001,
          _truckLocation.longitude + 0.0001,
        );
      });

      _checkGeofence();
      _getRoute(); // Update route when truck moves

      _simulateTruckMovement();
    });
  }

  Future<void> _getRoute() async {
    const apiKey = 'AIzaSyDerIF4uqPd7nqWta1wP_6pCIRVDdXQ6VQ'; // Replace with your API key

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_userLocation.latitude},${_userLocation.longitude}&destination=${_truckLocation.latitude},${_truckLocation.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final json = jsonDecode(response.body);

    if (json['routes'].isNotEmpty) {
      final points = json['routes'][0]['overview_polyline']['points'];
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(points);

      polylineCoordinates.clear();
      for (var point in result) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: polylineCoordinates,
            color: Colors.red,
            width: 5,
          ),
        };
      });
    }
  }

  void _checkGeofence() {
    double distance = Geolocator.distanceBetween(
      _userLocation.latitude,
      _userLocation.longitude,
      _truckLocation.latitude,
      _truckLocation.longitude,
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Waste Tracker")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _userLocation, zoom: 15),
        markers: {
          Marker(
            markerId: const MarkerId("user"),
            position: _userLocation,
            infoWindow: const InfoWindow(title: "Your Location"),
          ),
          Marker(
            markerId: const MarkerId("truck"),
            position: _truckLocation,
            infoWindow: const InfoWindow(title: "Truck Location"),
          ),
        },
        circles: {
          Circle(
            circleId: const CircleId("geofence"),
            center: _userLocation,
            radius: geofenceRadius,
            strokeColor: Colors.blue,
            strokeWidth: 2,
            fillColor: Colors.blue.withOpacity(0.3),
          ),
        },
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
