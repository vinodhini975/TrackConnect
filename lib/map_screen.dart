import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tracking_service.dart';

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
  String _truckName = "Locating..."; 
  String _truckAddress = "Fetching address...";
  StreamSubscription? _truckSubscription;
  StreamSubscription? _userPosSubscription;
  StreamSubscription? _trackingSubscription;
  String _userWard = "Default"; 

  final TrackingService _trackingService = TrackingService();

  static const double kEnterRadius = 5000.0;

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

    _trackingSubscription = _trackingService.selectedDriverStream.listen((driverId) {
      if (mounted) _listenToTruckFirestore();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startUserLiveTracking();
      _listenToTruckFirestore();
    });
  }

  Future<void> _fetchUserWard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey('ward')) {
          if (mounted) {
            setState(() => _userWard = doc.data()!['ward']);
            _listenToTruckFirestore();
          }
        }
      } catch (e) {}
    }
  }

  void _startUserLiveTracking() {
    _userPosSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _userLocation = newPosition);
        _getRoute();
      }
    });
  }

  void _listenToTruckFirestore() {
    _truckSubscription?.cancel();
    _truckSubscription = FirebaseFirestore.instance.collection('drivers').snapshots().listen((snapshot) {
      Map<String, dynamic>? targetDriverData;
      String? lockedId = _trackingService.selectedDriverId;

      try {
        final allDocs = snapshot.docs;

        if (lockedId != null) {
           final lockedDoc = allDocs.where((d) => d.id == lockedId).firstOrNull;
           if (lockedDoc != null) {
              targetDriverData = lockedDoc.data();
           } else if (!_trackingService.isManual) {
              _trackingService.selectDriver(null);
           }
        }

        if (targetDriverData == null && !_trackingService.isManual) {
           double minDistance = double.infinity;
           String? closestId;
           for (var doc in allDocs) {
              final data = doc.data();
              if ((data['ward']?.toString() ?? "Default") == _userWard && (data['dutySession']?['isActive'] ?? false)) {
                 double dLat = (data['currentLocation']?['latitude'] ?? data['latitude'] ?? 0.0).toDouble();
                 double dLng = (data['currentLocation']?['longitude'] ?? data['longitude'] ?? 0.0).toDouble();
                 if (dLat != 0) {
                   double dist = Geolocator.distanceBetween(_userLocation.latitude, _userLocation.longitude, dLat, dLng);
                   if (dist < kEnterRadius && dist < minDistance) {
                     minDistance = dist;
                     targetDriverData = data;
                     closestId = doc.id;
                   }
                 }
              }
           }
           if (closestId != null) _trackingService.selectDriver(closestId);
        }
      } catch (e) {}

      if (targetDriverData != null) {
        double lat = (targetDriverData!['currentLocation']?['latitude'] ?? targetDriverData!['latitude'] ?? 0.0).toDouble();
        double lng = (targetDriverData!['currentLocation']?['longitude'] ?? targetDriverData!['longitude'] ?? 0.0).toDouble();
        if (lat != 0.0) {
          if (mounted) {
            setState(() {
              _truckLocation = LatLng(lat, lng);
              _truckName = targetDriverData!['vehicleId']?.toString() ?? targetDriverData!['name']?.toString() ?? "Waste Truck";
            });
            _getAddressFromLatLng(lat, lng);
            _getRoute();
          }
        }
      }
    });
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        if (mounted) setState(() => _truckAddress = "${p.street}, ${p.subLocality}");
      }
    } catch (e) {}
  }

  Future<void> _getRoute() async {
    const apiKey = 'AIzaSyDerIF4uqPd7nqWta1wP_6pCIRVDdXQ6VQ'; 
    try {
      String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${_userLocation.latitude},${_userLocation.longitude}&destination=${_truckLocation.latitude},${_truckLocation.longitude}&key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final points = json['routes'][0]['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result = polylinePoints.decodePolyline(points);
          polylineCoordinates.clear();
          for (var point in result) polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          if (mounted) {
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  color: const Color(0xFF1A73E8),
                  width: 5,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
              };
            });
          }
        }
      }
    } catch (e) {}
  }

  void _updateCameraView() {
    if (_mapController == null) return;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        _userLocation.latitude < _truckLocation.latitude ? _userLocation.latitude : _truckLocation.latitude,
        _userLocation.longitude < _truckLocation.longitude ? _userLocation.longitude : _truckLocation.longitude,
      ),
      northeast: LatLng(
        _userLocation.latitude > _truckLocation.latitude ? _userLocation.latitude : _truckLocation.latitude,
        _userLocation.longitude > _truckLocation.longitude ? _userLocation.longitude : _truckLocation.longitude,
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _showDriversBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Text("Trucks in Your Ward", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('drivers').where('ward', isEqualTo: _userWard).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Text("No trucks registered in this ward."));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isActive = data['dutySession']?['isActive'] ?? false;
                    final String name = data['vehicleId'] ?? data['driverId'] ?? data['name'] ?? "Truck ${index + 1}";
                    final bool isSelected = _trackingService.selectedDriverId == docs[index].id;

                    return ListTile(
                      leading: Icon(Icons.local_shipping_rounded, color: isActive ? Colors.green : Colors.grey),
                      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.green : Colors.black)),
                      subtitle: Text(isActive ? "Active" : "Offline"),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      onTap: () {
                        _trackingService.selectDriver(docs[index].id, manual: true);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _truckSubscription?.cancel();
    _userPosSubscription?.cancel();
    _trackingSubscription?.cancel();
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
                markerId: const MarkerId("source"),
                position: _userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                anchor: const Offset(0.5, 1.0), 
                infoWindow: const InfoWindow(title: "My Location"),
              ),
              Marker(
                markerId: const MarkerId("destination"),
                position: _truckLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                anchor: const Offset(0.5, 1.0),
                infoWindow: InfoWindow(title: _truckName, snippet: _truckAddress),
              ),
            },
            polylines: _polylines,
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_mapStyle); // RESTORED UBER STYLE
              _updateCameraView();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          
          Positioned(
            top: 50, left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  const Text("LIVE TRACKING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    double dist = Geolocator.distanceBetween(_userLocation.latitude, _userLocation.longitude, _truckLocation.latitude, _truckLocation.longitude);
    String etaText = "LOCATING...";
    String distanceText = "";
    if (_truckName != "Locating...") {
      int mins = (dist / 400).ceil();
      etaText = "${mins < 1 ? 1 : mins} min";
      distanceText = "(${dist < 1000 ? "${dist.toInt()} m" : "${(dist / 1000).toStringAsFixed(1)} km"})";
    }

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
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
                    Row(
                      children: [
                        Text(etaText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                        const SizedBox(width: 8),
                        Text(distanceText, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    Text(_truckAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(_truckName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(onPressed: _showDriversBottomSheet, icon: const Icon(Icons.list_alt_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _updateCameraView,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Recenter View", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => launchUrl(Uri.parse("tel:+911234567890")),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2F2F7), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Icon(Icons.call_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
