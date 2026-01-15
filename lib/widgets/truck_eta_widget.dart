import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../notification_service.dart';
import '../tracking_service.dart';

class TruckEtaWidget extends StatefulWidget {
  final Position? userPosition;
  final VoidCallback onMapTap;

  const TruckEtaWidget({
    super.key, 
    required this.userPosition, 
    required this.onMapTap,
  });

  @override
  State<TruckEtaWidget> createState() => _TruckEtaWidgetState();
}

class _TruckEtaWidgetState extends State<TruckEtaWidget> {
  bool _isLocatingEnabled = true;
  String _userWard = "Default"; 
  String _currentTruckAddress = "Locating...";
  _GeoPos? _lastGeocodedPos;
  
  final TrackingService _trackingService = TrackingService();

  static const double kEnterRadius = 5000.0; // Increased radius for dashboard discovery

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
    _fetchUserWard();
  }

  Future<void> _fetchUserWard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final ward = doc.data()?['ward'] as String?;
          if (ward != null && mounted) setState(() => _userWard = ward);
        }
      } catch (e) {}
    }
  }

  Future<void> _getAddress(double lat, double lng) async {
    if (_lastGeocodedPos != null) {
      double d = Geolocator.distanceBetween(_lastGeocodedPos!.latitude, _lastGeocodedPos!.longitude, lat, lng);
      if (d < 100) return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        if (mounted) {
          setState(() {
            _currentTruckAddress = "${p.street}, ${p.subLocality}";
            _lastGeocodedPos = _GeoPos(lat, lng);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _checkLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (mounted) setState(() => _isLocatingEnabled = serviceEnabled && permission != LocationPermission.deniedForever);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _trackingService.selectedDriverStream,
      initialData: _trackingService.selectedDriverId,
      builder: (context, trackingSnapshot) {
        final String? lockedId = trackingSnapshot.data;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
          builder: (context, snapshot) {
            bool hasData = false;
            Map<String, dynamic>? activeDriverData;

            if (snapshot.hasData && _isLocatingEnabled) {
              final allDrivers = snapshot.data!.docs.map((d) {
                var data = d.data() as Map<String, dynamic>;
                data['id'] = d.id;
                return data;
              }).toList();

              // 1. Priority: User Selected Driver (even if in different ward or far)
              if (lockedId != null) {
                final lockedData = allDrivers.where((d) => d['id'] == lockedId).firstOrNull;
                if (lockedData != null) {
                   activeDriverData = lockedData;
                   hasData = true;
                }
              } 
              
              // 2. Fallback: Search Ward if no manual selection
              if (!hasData && widget.userPosition != null) {
                final wardDrivers = allDrivers.where((d) => (d['ward']?.toString() ?? "Default") == _userWard).toList();
                
                double minDistance = double.infinity;
                for (var data in wardDrivers) {
                  if (data['dutySession']?['isActive'] ?? false) {
                     double dLat = (data['currentLocation']?['latitude'] ?? data['latitude'] ?? 0.0).toDouble();
                     double dLng = (data['currentLocation']?['longitude'] ?? data['longitude'] ?? 0.0).toDouble();
                     if (dLat != 0) {
                       double dist = Geolocator.distanceBetween(widget.userPosition!.latitude, widget.userPosition!.longitude, dLat, dLng);
                       if (dist < kEnterRadius && dist < minDistance) {
                         minDistance = dist;
                         activeDriverData = data;
                         hasData = true;
                       }
                     }
                  }
                }
              }
            }

            int? minutes;
            double? distance;
            if (hasData && activeDriverData != null) {
                double tLat = (activeDriverData['currentLocation']?['latitude'] ?? activeDriverData['latitude'] ?? 0.0).toDouble();
                double tLng = (activeDriverData['currentLocation']?['longitude'] ?? activeDriverData['longitude'] ?? 0.0).toDouble();
                
                if (widget.userPosition != null) {
                  distance = Geolocator.distanceBetween(widget.userPosition!.latitude, widget.userPosition!.longitude, tLat, tLng);
                  minutes = (distance / 400).ceil();
                }
                _getAddress(tLat, tLng);
            }
            
            return _buildEtaCard(context, activeDriverData, distance, minutes);
          },
        );
      }
    );
  }

  Widget _buildEtaCard(BuildContext context, Map<String, dynamic>? driverData, double? distance, int? minutes) {
    Color accentColor = const Color(0xFF00C853);
    String statusLabel = "No Active Trucks";
    String truckName = "Waste Truck";
    
    if (driverData != null) {
      truckName = driverData['vehicleId']?.toString() ?? driverData['name']?.toString() ?? "Waste Truck";
      bool isActive = driverData['dutySession']?['isActive'] ?? false;
      statusLabel = isActive ? "Truck tracking active" : "Selected Truck (Offline)";
      if (!isActive) accentColor = Colors.grey;
    }

    String etaValue = "-";

    if (driverData != null && minutes != null) {
        etaValue = minutes.toString();
        if (minutes > 5 && accentColor != Colors.grey) accentColor = const Color(0xFFFF9500);
        if (distance != null && distance > 2000 && accentColor != Colors.grey) accentColor = const Color(0xFFFF3B30);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 80, color: accentColor.withOpacity(0.08), child: Center(child: Icon(Icons.local_shipping_rounded, color: accentColor, size: 32))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text(statusLabel.toUpperCase(), overflow: TextOverflow.ellipsis, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5))),
                          if (distance != null)
                            Text(distance < 1000 ? "${distance.toInt()}m" : "${(distance/1000).toStringAsFixed(1)}km", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(truckName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(_currentTruckAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: widget.onMapTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded, size: 12, color: Colors.grey[700]),
                              const SizedBox(width: 5),
                              const Text("LIVE TRACK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF424242))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 90,
                color: accentColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(etaValue, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                    const Text("MIN", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeoPos {
  final double latitude;
  final double longitude;
  _GeoPos(this.latitude, this.longitude);
}
