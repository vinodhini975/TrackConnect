import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../notification_service.dart';

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
  String? _lockedDriverId; // The ID of the truck we are currently tracking
  bool _hasNotified = false;
  String _userWard = "Default"; // Placeholder for user's ward
  
  // Constants (in meters)
  static const double kEnterRadius = 2000.0; // Start tracking when closer than this
  static const double kExitRadius = 2500.0;  // Stop tracking when further than this

  static const double kRouteBuffer = 500.0;
  
  // TESTING: MOCK DATA TOGGLE
  final bool _useMockData = true; // Set to FALSE for real production use
  int _mockScenario = 0; 

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
    _fetchUserWard();
    
    if (_useMockData) {
      // Cycle through scenarios every 5 seconds
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
           setState(() {
             _mockScenario = (_mockScenario + 1) % 4; // 0,1,2,3
             debugPrint("Mock Scenario Updated to: $_mockScenario");
           });
        }
        return mounted;
      });
    }
  }

  Future<void> _fetchUserWard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final ward = doc.data()?['ward'] as String?;
        if (ward != null && mounted) {
          setState(() {
            _userWard = ward;
          });
        }
      }
    }
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
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        
        // MOCK DATA OVERRIDE
        if (_useMockData && widget.userPosition != null) {
             // Mock Base Data
             Map<String, dynamic> mockData = {
               'vehicleId': 'TEST-TRUCK-${_mockScenario}',
               'dutySession': {'isActive': true},
               'isOnRoute': true, 
             };
             double mockDist = 1000;
             
             if (_mockScenario == 0) {
               // 1. Normal Tracking (Far, No Route data)
               mockDist = 1200; // 3 mins
             } else if (_mockScenario == 1) {
               // 2. Off Route (Close physically, but route is false)
               mockDist = 200;
               mockData['isOnRoute'] = false;
             } else if (_mockScenario == 2) {
               // 3. Approaching (Close & On Route)
               mockDist = 200;
               mockData['isOnRoute'] = true;
             } else {
                // 4. Searching/None
                return Container(
                  height: 100, 
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: const Center(child: Text("Simulating: No Trucks Found")),
                );
             }

             // Render the widget with Mock Data
             return _buildEtaCard(context, mockData, mockDist, (mockDist/400).ceil());
        }

        bool hasData = false;
        Map<String, dynamic>? activeDriverData;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty && widget.userPosition != null && _isLocatingEnabled) {
          try {
            // STEP 1: GATEKEEPER (Filter by Profile Ward Only)
            final wardDrivers = snapshot.data!.docs.where((doc) {
               final d = doc.data() as Map<String, dynamic>;
               final dWard = d['ward']?.toString() ?? "Default";
               return dWard == _userWard;
            }).toList();

            // STEP 2: TRACKER (Lock-on Logic)

            // MODE A: Locked Driver Logic
            if (_lockedDriverId != null) {
              final lockedDoc = wardDrivers.where((d) => d.id == _lockedDriverId).firstOrNull;
              
              if (lockedDoc != null) {
                final data = lockedDoc.data() as Map<String, dynamic>;
                
                bool isActive = false;
                 if (data.containsKey('dutySession') && data['dutySession'] is Map) {
                  isActive = data['dutySession']['isActive'] ?? false;
                }
                
                double dLat = 0.0, dLng = 0.0;
                List<dynamic> routePoints = [];

                if (data.containsKey('currentLocation') && data['currentLocation'] is Map) {
                    final loc = data['currentLocation'] as Map<String, dynamic>;
                    dLat = (loc['latitude'] ?? 0.0).toDouble();
                    dLng = (loc['longitude'] ?? 0.0).toDouble();
                } else {
                   dLat = (data['latitude'] ?? 0.0).toDouble();
                   dLng = (data['longitude'] ?? 0.0).toDouble();
                }
                
                if (data.containsKey('routePath') && data['routePath'] is List) {
                   routePoints = data['routePath'];
                }

                double dist = Geolocator.distanceBetween(
                    widget.userPosition!.latitude, widget.userPosition!.longitude, dLat, dLng);
                
                bool isOnRoute = true;
                if (routePoints.isNotEmpty) {
                   isOnRoute = _isLocationNearPolyline(widget.userPosition!, routePoints);
                }

                // Release Condition
                if (!isActive || dist > kExitRadius) {
                   activeDriverData = null; 
                   if (_lockedDriverId != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                         if(mounted) setState(() => _lockedDriverId = null);
                      });
                   }
                } else {
                   activeDriverData = data;
                   activeDriverData!['isOnRoute'] = isOnRoute;
                   hasData = true;
                }
              } else {
                 if (_lockedDriverId != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       if(mounted) setState(() => _lockedDriverId = null);
                    });
                 }
              }
            } 
            
            // MODE B: Unlocked Scan Logic
            if (_lockedDriverId == null) {
              double minDistance = double.infinity;
              Map<String, dynamic>? closestDriver;
              String? closestId;

              for (var doc in wardDrivers) {
                final data = doc.data() as Map<String, dynamic>;
                
                bool isActive = false;
                if (data.containsKey('dutySession') && data['dutySession'] is Map) {
                  isActive = data['dutySession']['isActive'] ?? false;
                }

                if (isActive) {
                   double dLat = 0.0, dLng = 0.0;
                   if (data.containsKey('currentLocation') && data['currentLocation'] is Map) {
                      final loc = data['currentLocation'] as Map<String, dynamic>;
                      dLat = (loc['latitude'] ?? 0.0).toDouble();
                      dLng = (loc['longitude'] ?? 0.0).toDouble();
                   } else {
                      dLat = (data['latitude'] ?? 0.0).toDouble();
                      dLng = (data['longitude'] ?? 0.0).toDouble();
                   }

                   if (dLat != 0 && dLng != 0) {
                     double dist = Geolocator.distanceBetween(
                        widget.userPosition!.latitude, widget.userPosition!.longitude, dLat, dLng);
                     
                     if (dist < kEnterRadius && dist < minDistance) {
                        minDistance = dist;
                        closestDriver = data;
                        closestId = doc.id;
                     }
                   }
                }
              }

              if (closestDriver != null && closestId != null) {
                 activeDriverData = closestDriver;
                 hasData = true;
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                    if(mounted && _lockedDriverId != closestId) {
                       setState(() => _lockedDriverId = closestId);
                    }
                 });
              }
            }
          } catch (e) {
            debugPrint("Tracking logic error: $e");
          }
        }

        int? minutes;
        double? distance;
        
        if (hasData && activeDriverData != null) {
          try {
            final truckData = activeDriverData!; // Force unwrap since we checked hasData
            
            double truckLat = 0.0;
            double truckLng = 0.0;

            if (truckData.containsKey('currentLocation') && truckData['currentLocation'] is Map) {
              final locationMap = truckData['currentLocation'] as Map<String, dynamic>;
              truckLat = (locationMap['latitude'] ?? 0.0).toDouble();
              truckLng = (locationMap['longitude'] ?? 0.0).toDouble();
            } else {
              truckLat = (truckData['latitude'] ?? 0.0).toDouble();
              truckLng = (truckData['longitude'] ?? 0.0).toDouble();
            }

            distance = Geolocator.distanceBetween(
              widget.userPosition!.latitude, widget.userPosition!.longitude,
              truckLat, truckLng,
            );

            // Notification Logic
            if (distance != null) {
              if (distance! < 800 && !_hasNotified) {
                 NotificationService.showLocalNotification(
                   "Truck Arriving", 
                   "Waste collection truck is nearby (${distance!.toInt()}m away)"
                 );
                 _hasNotified = true;
              } else if (distance! > 1000) {
                 _hasNotified = false; 
              }
              
              minutes = (distance! / 400).ceil();
              if (minutes! < 1) minutes = 1;
            }
          } catch (e) {
            hasData = false;
            debugPrint("Error parsing truck data: $e");
          }
        }
        
        return _buildEtaCard(context, activeDriverData, distance, minutes);
      },
    );
  }

  Widget _buildEtaCard(BuildContext context, Map<String, dynamic>? driverData, double? distance, int? minutes) {
    Color accentColor = const Color(0xFF00C853);
    String statusLabel = "Standby";
    IconData statusIcon = Icons.sensors_off_rounded;
    String etaValue = "-";
    String truckIdentifier = "Waste Truck";

    bool hasData = (driverData != null);
    
    // 1. Determine Identity
    if (hasData) {
        if (driverData!.containsKey('vehicleId')) {
           truckIdentifier = driverData['vehicleId']?.toString() ?? "Waste Truck";
        } else if (driverData.containsKey('name')) {
           truckIdentifier = driverData['name']?.toString() ?? "Waste Truck";
        }
    }

    // 2. Determine Status (Route Aware)
    bool isNextStop = false;
    if (hasData && driverData!.containsKey('isOnRoute')) {
       if (driverData['isOnRoute'] == false) {
         statusLabel = "Nearby (Off Route)";
         accentColor = Colors.grey;
         statusIcon = Icons.alt_route_rounded;
         etaValue = "~"; 
       } else {
         isNextStop = true;
       }
    } else if (hasData) {
       // Legacy fallback if no route data
       isNextStop = true;
    }

    // 3. Determine ETA / Color
    if (hasData && minutes != null && distance != null && isNextStop) {
      if (distance! > 500) {
        etaValue = "-";
        accentColor = const Color(0xFFFF3B30);
        statusLabel = "Quite far";
        statusIcon = Icons.location_searching_rounded;
      } else {
        etaValue = minutes.toString();
        statusIcon = Icons.local_shipping_rounded;
        statusLabel = "On its way";
        
        if (minutes! > 5) {
          accentColor = const Color(0xFFFF9500);
          statusLabel = "Approaching";
          statusIcon = Icons.moped_rounded;
        }
      }
    } else if (!hasData) {
        etaValue = "-";
        statusLabel = "No Active Trucks";
        statusIcon = Icons.sentiment_dissatisfied_rounded;
    }

    // 4. Render Card
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
          height: 110, 
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
                          Flexible(
                            child: Text(
                              statusLabel.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (distance != null && hasData)
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
                        truckIdentifier,
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
  }

  bool _isLocationNearPolyline(Position userPos, List<dynamic> points) {
    // Simple implementation: Check if user is within buffer of ANY route point
    // A robust version would check distance to the *segment lines* between points.
    for (var p in points) {
      if (p is Map) { // GeoPoint or Map
        double pLat = (p['latitude'] ?? 0.0).toDouble();
        double pLng = (p['longitude'] ?? 0.0).toDouble();
        double dist = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, pLat, pLng);
        if (dist < kRouteBuffer) return true;
      } else if (p is GeoPoint) {
         double dist = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, p.latitude, p.longitude);
         if (dist < kRouteBuffer) return true;
      }
    }
    return false;
  }
}
