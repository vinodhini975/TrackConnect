import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class GPSLocation extends StatefulWidget {
  const GPSLocation({super.key});

  @override
  State<GPSLocation> createState() => _GPSLocationState();
}

class _GPSLocationState extends State<GPSLocation> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  final double _geofenceRadius = 50.0; // 50 meters
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  Timer? _locationUpdateTimer;

  final Set<Polyline> _polylines = {};
  LatLng? _targetTruckLocation; // Removed hardcoded coordinates

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _getUserLocation();

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (mounted) {
        _getUserLocation();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _initNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);
    _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        if (_mapController != null && _currentLocation != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15),
          );
        }

        if (_currentLocation != null && _targetTruckLocation != null) {
          _drawPolyline();
          _checkGeofence();
        }
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _drawPolyline() {
    if (_currentLocation == null || _targetTruckLocation == null) return;

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: [_currentLocation!, _targetTruckLocation!],
          color: Colors.green,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    });
  }

  void _checkGeofence() {
    if (_currentLocation == null || _targetTruckLocation == null) return;

    double distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _targetTruckLocation!.latitude,
      _targetTruckLocation!.longitude,
    );

    if (distance <= _geofenceRadius) {
      _showNotification("🚛 Waste Truck Alert", "A truck is near your location.");
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, platformDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waste Truck Tracker')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId("currentLocation"),
                position: _currentLocation!,
                infoWindow: const InfoWindow(title: "Your Location"),
              ),
              if (_targetTruckLocation != null)
                Marker(
                  markerId: const MarkerId("wasteTruckLocation"),
                  position: _targetTruckLocation!,
                  infoWindow: const InfoWindow(title: "Waste Truck"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
            },
            polylines: _polylines,
          ),
    );
  }
}
