import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _locationStatus = "Location permission not granted";
  Position? _currentPosition;
  bool _isNavigatedToMap = false; // Prevent repeated navigation

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = "Location services are disabled.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = "Location permission denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationStatus = "Location permissions permanently denied.";
      });
      return;
    }

    // ✅ More Accurate Live Location Tracking
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best, // Use highest accuracy
        distanceFilter: 1, // Updates every 1 meter
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _locationStatus =
        "Live Tracking - Lat: ${position.latitude}, Long: ${position.longitude}";
      });

      // ✅ Navigate to MapScreen only once to avoid flickering
      if (mounted && !_isNavigatedToMap) {
        _isNavigatedToMap = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MapScreen(userLocation: position)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to Waste Tracker! 🌍",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text("For real-time tracking, we need location access:"),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: _requestLocationPermission,
              child: Text("Allow Location Access"),
            ),
            SizedBox(height: 15),
            Text(
              _locationStatus,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
