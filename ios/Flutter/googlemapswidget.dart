import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LiveMap extends StatefulWidget {
  @override
  _LiveMapState createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  GoogleMapController? _mapController;
  LatLng _truckLocation = LatLng(13.9601570, 75.5108460); // Truck's fixed location
  LatLng _userLocation = LatLng(0, 0); // User's location (to be updated dynamically)

  Marker? _userMarker;
  Marker? _truckMarker;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getLiveLocation();
  }

  Future<void> _getLiveLocation() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permission denied.");
        return;
      }

      // Get live location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _userMarker = Marker(
          markerId: MarkerId("user_location"),
          position: _userLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        _truckMarker = Marker(
          markerId: MarkerId("truck_location"),
          position: _truckLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );

        // Add polyline to connect user and truck
        _polylines = {
          Polyline(
            polylineId: PolylineId("route"),
            color: Colors.blue,
            width: 5,
            points: [_userLocation, _truckLocation],
          ),
        };
      });

      // Move the map camera to the user's location
      _mapController?.animateCamera(CameraUpdate.newLatLng(_userLocation));
    } catch (e) {
      print("Error getting live location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live GPS Tracking on Map")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _truckLocation, zoom: 15),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: {
          if (_userMarker != null) _userMarker!,
          if (_truckMarker != null) _truckMarker!,
        },
        polylines: _polylines,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location),
        onPressed: _getLiveLocation,
      ),
    );
  }
}
