import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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

  final double geofenceRadius = 500; // meters
  bool isTruckInsideGeofence = false;

  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  Timer? _truckMovementTimer;

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
      _simulateTruckMovement();
      _getRoute();
    });
  }

  void _startUserLiveTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      
      double distance = Geolocator.distanceBetween(
        _userLocation.latitude,
        _userLocation.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      
      if (distance > 10) {
        if (mounted) {
          setState(() {
            _userLocation = newPosition;
          });
        }
      }

      if (_mapController != null) {
        // Smoothly animate to keep user in view if needed, or let them scroll
        // _mapController!.animateCamera(CameraUpdate.newLatLng(_userLocation));
      }

      _getRoute();
    });
  }

  void _simulateTruckMovement() {
    _truckMovementTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        final newTruckLocation = LatLng(
          _truckLocation.latitude + 0.00005,
          _truckLocation.longitude + 0.00005,
        );
        
        setState(() {
          _truckLocation = newTruckLocation;
        });

        _checkGeofence();
        _getRoute();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _getRoute() async {
    // TODO: Replace with a valid API Key and restrict it in Google Console
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
                  color: Colors.black, // Changed to black to match the clean style
                  width: 4,
                ),
              };
            });
          }
        }
      }
    } catch (e) {
      print('Error getting route: $e');
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
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<double> _getDistance() async {
    return Geolocator.distanceBetween(
      _userLocation.latitude,
      _userLocation.longitude,
      _truckLocation.latitude,
      _truckLocation.longitude,
    );
  }

  @override
  void dispose() {
    _truckMovementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _userLocation, zoom: 15),
            markers: {
              Marker(
                markerId: const MarkerId("user"),
                position: _userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // hueBlack not supported
                infoWindow: const InfoWindow(title: "You"),
              ),
              Marker(
                markerId: const MarkerId("truck"),
                position: _truckLocation,
                // Ideally use a custom truck icon
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), 
                infoWindow: const InfoWindow(title: "Waste Truck"),
              ),
            },
            polylines: _polylines,
            circles: {
              Circle(
                circleId: const CircleId("geofence"),
                center: _truckLocation,
                radius: geofenceRadius,
                strokeColor: Colors.transparent,
                strokeWidth: 0,
                fillColor: Colors.green.withOpacity(0.1),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              controller.setMapStyle(_mapStyle);
            },
            myLocationEnabled: false, // Hide default blue dot
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          
          // 2. Top Header (Pick-up Location Style)
          Positioned(
            top: 50,
            left: 20,
            child: _buildTopHeader(),
          ),
          
          // 3. Bottom Driver Panel
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
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Location", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                "PICK-UP POINT", 
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return FutureBuilder<double>(
      future: _getDistance(),
      builder: (context, snapshot) {
        String etaText = "CALCULATING...";
        String distanceText = "";
        
        if (snapshot.hasData) {
          double distance = snapshot.data!;
          // Approx speed 30km/h = 500m/min
          int minutes = (distance / 500).ceil();
          if (minutes < 1) minutes = 1;
          
          etaText = "ARRIVING IN $minutes MIN";
          if (distance < 1000) {
            distanceText = "${distance.toInt()} m away";
          } else {
            distanceText = "${(distance / 1000).toStringAsFixed(1)} km away";
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green Status Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFF4CAF50), // Green
              child: Text(
                etaText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
            ),
            
            // Driver Info Panel
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver Avatar
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.local_shipping, size: 35, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "WASTE COLLECTOR",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Vehicle: Truck #402 • $distanceText",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                            ),
                          ],
                        ),
                      ),
                      
                      // Call Icon
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.black87),
                          onPressed: () async {
                             final Uri launchUri = Uri(
                               scheme: 'tel',
                               path: '+1234567890',
                             );
                             try {
                               // Check explicitly for phone support if needed or simply try launch
                               // canLaunchUrl usually fails on some emulators for tel schemes without specific queries
                               if (!await launchUrl(launchUri)) {
                                throw 'Could not launch $launchUri';
                               }
                             } catch (e) {
                               debugPrint("Error calling: $e");
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("Cannot call on this device")),
                               );
                             }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                         _getRoute(); // Refresh route
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1744), // Red
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text(
                        "REFRESH ROUTE", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}