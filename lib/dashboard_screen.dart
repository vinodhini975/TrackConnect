import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';
import 'on_demand_service_screen.dart';
import 'sell_waste_screen.dart';
import 'complaint_screen.dart';
import 'auth_service.dart';
import 'widgets/truck_eta_widget.dart';
import 'widgets/live_tracking_banner.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();
  Position? _userPosition;

  bool _isNavigating = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      if (mounted) setState(() => _userPosition = position);
    } catch (e) {
      print("Could not get user position for ETA: $e");
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  Future<void> _navigateToMap() async {
    if (_isNavigating) return;
    _isNavigating = true;
    setState(() => _isLoading = true);
    
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => MapScreen(userLocation: position)));
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _isNavigating = false;
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }
  
  void _showScreen(Widget screen) {
    if (_isNavigating) return;
    _isNavigating = true;
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen))
        .then((_) => _isNavigating = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            backgroundColor: Colors.white,
            expandedHeight: 140,
            stretch: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Waste Tracker", 
                style: TextStyle(
                  color: Colors.black, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: -0.5
                )
              ),
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                onPressed: () => _showScreen(const NotificationScreen()),
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.black),
              ),
              IconButton(
                onPressed: () => _authService.signOut(),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${user?.displayName ?? 'Green Warrior'}",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Every bit counts. Let's keep it clean.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    LiveTrackingBanner(
                      isLoading: _isLoading,
                      onTap: _navigateToMap,
                    ),
                    const SizedBox(height: 16),
                    TruckEtaWidget(
                      userPosition: _userPosition,
                      onMapTap: _navigateToMap,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Our Services",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildServiceCard(
                          icon: Icons.local_shipping_rounded,
                          title: "Track Truck",
                          color: const Color(0xFFE8F5E9),
                          onTap: _navigateToMap,
                        ),
                        _buildServiceCard(
                          icon: Icons.bolt_rounded,
                          title: "On-Demand",
                          color: const Color(0xFFF1F8E9),
                          onTap: () => _showScreen(const OnDemandServiceScreen()),
                        ),
                        _buildServiceCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: "Sell & Earn",
                          color: const Color(0xFFE0F2F1),
                          onTap: () => _showScreen(const SellWasteScreen()),
                        ),
                        _buildServiceCard(
                          icon: Icons.gavel_rounded,
                          title: "Complaints",
                          color: const Color(0xFFE8F5E9),
                          onTap: () => _showScreen(const ComplaintScreen()),
                        ),
                        _buildServiceCard(
                          icon: Icons.event_available_rounded,
                          title: "Schedule",
                          color: const Color(0xFFF1F8E9),
                          onTap: () => _showScreen(const ScheduleScreen()),
                        ),
                        _buildServiceCard(
                          icon: Icons.tune_rounded,
                          title: "Settings",
                          color: const Color(0xFFF5F5F7),
                          onTap: () => _showScreen(const SettingsScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black87, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}