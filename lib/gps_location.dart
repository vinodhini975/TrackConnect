import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async'; // Add timer import

class GPSLocation extends StatefulWidget {
  @override
  _GPSLocationState createState() => _GPSLocationState();
}

class _GPSLocationState extends State<GPSLocation> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  double _geofenceRadius = 10.0; // 10 meters
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  Set<Polyline> _polylines = {}; // Stores the polyline
  final LatLng wasteTruckLocation = LatLng(13.961046, 75.511070); // Truck location

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _getUserLocation();

    // Set up a periodic location update
    const oneSec = const Duration(seconds: 10);
    Timer.periodic(oneSec, (Timer timer) {
      if (mounted) {
        _getUserLocation();
      } else {
        timer.cancel();
      }
    });
  }

  /// Initialize Local Notifications
  void _initNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);
    _notificationsPlugin.initialize(initSettings);
  }

  /// Get Current Location
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("❌ Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("❌ Location permission permanently denied.");
      return;
    }

    try {
      // Get user's current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Set user's location
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        // Move camera to current location
        if (_mapController != null && _currentLocation != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15),
          );
        }

        // Draw polyline once we have the current location
        if (_currentLocation != null) {
          _drawPolyline();
        }

        _checkGeofence(); // Check geofence when location is updated
      }
    } catch (e) {
      print("❌ Error getting location: $e");
    }
  }

  /// Draw Polyline from User to Truck
  void _drawPolyline() {
    if (_currentLocation == null) {
      print("❌ Cannot draw polyline: Current location is NULL.");
      return;
    }

    print("🔹 Drawing polyline from: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
    print("🔹 To: ${wasteTruckLocation.latitude}, ${wasteTruckLocation.longitude}");

    // Make sure we're adding the polyline on the UI thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: PolylineId("route"),
              visible: true,
              points: [_currentLocation!, wasteTruckLocation],
              color: Colors.red,
              width: 8,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
          print("✅ Polyline added: ${_polylines.length} polylines in set");
        });
      }
    });
  }

  /// Check if the user is inside the geofence
  void _checkGeofence() {
    if (_currentLocation == null) return;

    double distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      wasteTruckLocation.latitude,
      wasteTruckLocation.longitude,
    );

    if (distance <= _geofenceRadius) {
      print("🚛 Truck is near your location!");
      _showNotification("🚛 Waste Truck Alert", "A truck is near your location.");
    } else {
      print("🚛 Truck is far from your location: $distance meters away.");
    }
  }

  /// Show Local Notification
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, platformDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Waste Truck Tracker')),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
              // Add a delay before drawing the polyline
              Future.delayed(Duration(milliseconds: 500), () {
                _drawPolyline();
              });
            },
            markers: {
              Marker(
                markerId: MarkerId("currentLocation"),
                position: _currentLocation!,
                infoWindow: InfoWindow(title: "Your Location"),
              ),
              Marker(
                markerId: MarkerId("wasteTruckLocation"),
                position: wasteTruckLocation,
                infoWindow: InfoWindow(title: "Waste Truck"),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
              ),
            },
            polylines: _polylines, // Displays polyline
            circles: {
              Circle(
                circleId: CircleId("geofenceRadius"),
                center: wasteTruckLocation,
                radius: _geofenceRadius,
                fillColor: Colors.blue.withOpacity(0.3),
                strokeWidth: 1,
              ),
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "refreshLocation",
                  onPressed: () {
                    _getUserLocation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Refreshing location...')),
                    );
                  },
                  child: Icon(Icons.my_location),
                  tooltip: 'Get Current Location',
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "forceDrawPolyline",
                  onPressed: () {
                    _drawPolyline();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Drawing route to truck...')),
                    );
                  },
                  child: Icon(Icons.route),
                  tooltip: 'Draw Route to Truck',
                  backgroundColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}