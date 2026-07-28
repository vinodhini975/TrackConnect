import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/truck_provider.dart';
import '../../data/models/truck_location.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimens.dart';
import '../home/complaint_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _userPos;

  final String _premiumMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
    {"featureType": "water", "stylers": [{"color": "#e9e9e9"}]}
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildFloatingStatus(),
          _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<TruckProvider>(
      builder: (context, provider, _) {
        final truck = provider.truckLocation;
        return GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(12.9716, 77.5946), zoom: 14),
          style: _premiumMapStyle,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: {
             if (truck != null)
               Marker(
                 markerId: const MarkerId("truck"),
                 position: LatLng(truck.latitude, truck.longitude),
                 icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
               ),
          },
          onMapCreated: (c) => _mapController = c,
        );
      },
    );
  }

  Widget _buildFloatingStatus() {
    return Positioned(
      top: 60, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
        ),
        child: Row(
          children: [
            const Icon(Icons.circle, color: AppColors.primary, size: 12),
            const SizedBox(width: 12),
            const Expanded(child: Text("TRUCK #KA34YO78", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(100)),
              child: const Text("5 MIN ETA", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusExtraLarge)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppDimens.paddingLarge),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 36)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Girish Kumar", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        Text("Near JP Nagar 5th Phase", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.call_rounded, color: AppColors.primary))
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComplaintScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange.shade900,
                    elevation: 0,
                  ),
                  child: const Text("REPORT AN ISSUE", style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
