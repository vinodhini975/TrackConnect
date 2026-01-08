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
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').limit(1).snapshots(),
      builder: (context, snapshot) {
        bool hasData = snapshot.hasData && 
                      snapshot.data!.docs.isNotEmpty && 
                      widget.userPosition != null && 
                      _isLocatingEnabled;

        int? minutes;
        double? distance;
        
        if (hasData) {
          final truckData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final truckLat = truckData['latitude'] as double;
          final truckLng = truckData['longitude'] as double;

          distance = Geolocator.distanceBetween(
            widget.userPosition!.latitude, widget.userPosition!.longitude,
            truckLat, truckLng,
          );

          minutes = (distance / 400).ceil();
          if (minutes < 1) minutes = 1;
        }

        // Always show the card, just change content if no data
        Color accentColor = const Color(0xFF00C853);
        String statusLabel = "Standby";
        IconData statusIcon = Icons.sensors_off_rounded;
        String etaValue = "-";

        if (hasData && minutes != null) {
          etaValue = minutes.toString();
          statusIcon = Icons.local_shipping_rounded;
          statusLabel = "On its way";
          
          if (minutes > 15) {
            accentColor = const Color(0xFFFF3B30);
            statusLabel = "Quite far";
            statusIcon = Icons.location_searching_rounded;
          } else if (minutes > 5) {
            accentColor = const Color(0xFFFF9500);
            statusLabel = "Approaching";
            statusIcon = Icons.moped_rounded;
          }
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 75,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      bottomLeft: Radius.circular(28),
                    ),
                  ),
                  child: Center(
                    child: Icon(statusIcon, color: accentColor, size: 30),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                                letterSpacing: 1.1,
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
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasData ? "Truck #402" : "Searching for truck...",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: widget.onMapTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                  "Open Map",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[700],
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
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        etaValue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const Text(
                        "MIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
