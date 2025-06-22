import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final Position userLocation;


  MapScreen({required this.userLocation});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  late LatLng _userLocation;
  LatLng _truckLocation = LatLng(13.960178, 75.510884); // Initial truck location

  final double geofenceRadius = 500; // 500 meters geofence
  bool isTruckInsideGeofence = false;

  @override
  void initState() {
    super.initState();
    _userLocation = LatLng(widget.userLocation.latitude, widget.userLocation.longitude);

    _startUserLiveTracking();
    _simulateTruckMovement(); // Simulate truck movement (replace with real GPS later)
  }

  // Live user tracking
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
    });
  }

  // Simulate truck movement (replace with real truck GPS)
  void _simulateTruckMovement() {
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _truckLocation = LatLng(_truckLocation.latitude + 0.0001, _truckLocation.longitude + 0.0001);
      });
      _checkGeofence();
      _simulateTruckMovement();
    });
  }

  // Check if truck is inside geofence
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

  // Show alert (Replace with push notification later)
  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Waste Tracker")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _userLocation, zoom: 15),
        markers: {
          Marker(
            markerId: MarkerId("user"),
            position: _userLocation,
            infoWindow: InfoWindow(title: "Your Location"),
          ),
          Marker(
            markerId: MarkerId("truck"),
            position: _truckLocation,
            infoWindow: InfoWindow(title: "Truck Location"),
          ),
        },
        circles: {
          Circle(
            circleId: CircleId("geofence"),
            center: _userLocation,
            radius: geofenceRadius,
            strokeColor: Colors.blue,
            strokeWidth: 2,
            fillColor: Colors.blue.withOpacity(0.3),
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
