import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLocatingEnabled = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLocatingEnabled = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLocatingEnabled = false);
        return;
      }

      if (mounted) setState(() => _isLocatingEnabled = true);
    } catch (e) {
      if (mounted) setState(() => _isLocatingEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').limit(1).snapshots(),
      builder: (context, snapshot) {
        // Handle potential errors in StreamBuilder
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error fetching truck data"), duration: Duration(seconds: 2))
              );
            }
          });
        }

        bool hasData = snapshot.hasData && 
                      snapshot.data!.docs.isNotEmpty && 
                      widget.userPosition != null && 
                      _isLocatingEnabled &&
                      !snapshot.hasError;

        int? minutes;
        double? distance;
        
        if (hasData) {
          try {
            final truckData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final truckLat = (truckData['latitude'] ?? 0.0).toDouble();
            final truckLng = (truckData['longitude'] ?? 0.0).toDouble();

            distance = Geolocator.distanceBetween(
              widget.userPosition!.latitude, widget.userPosition!.longitude,
              truckLat, truckLng,
            );

            minutes = (distance / 400).ceil();
            if (minutes < 1) minutes = 1;
          } catch (e) {
            hasData = false; // Fallback to standby on cast error
          }
        }

        Color accentColor = const Color(0xFF00C853);
        String statusLabel = "Standby";
        IconData statusIcon = Icons.sensors_off_rounded;
        String etaValue = "-";

        if (hasData && minutes != null && distance != null) {
          if (distance > 500) {
            etaValue = "-";
            accentColor = const Color(0xFFFF3B30);
            statusLabel = "Quite far";
            statusIcon = Icons.location_searching_rounded;
          } else {
            etaValue = minutes.toString();
            statusIcon = Icons.local_shipping_rounded;
            statusLabel = "On its way";
            
            if (minutes > 5) {
              accentColor = const Color(0xFFFF9500);
              statusLabel = "Approaching";
              statusIcon = Icons.moped_rounded;
            }
          }
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 110, // Slightly increased height to prevent overflow
              child: Row(
                children: [
                  Container(
                    width: 70,
                    color: accentColor.withOpacity(0.08),
                    child: Center(
                      child: Icon(statusIcon, color: accentColor, size: 28),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                statusLabel.toUpperCase(),
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (distance != null)
                                Text(
                                  distance < 1000 
                                      ? '${distance.toInt()} m' 
                                      : '${(distance / 1000).toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasData ? "Truck #402" : "Searching for truck...",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: widget.onMapTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_rounded, size: 12, color: Colors.grey[700]),
                                  const SizedBox(width: 5),
                                  Text(
                                    "LIVE TRACK",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey[700],
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 85,
                    color: accentColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          etaValue,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const Text(
                          "MIN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
