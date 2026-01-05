import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'map_screen.dart';
import 'schedule_screen.dart';
import 'info_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isNavigating = false; // Flag to prevent multiple taps
  bool _isLoading = false; // Flag to show loading indicator
  
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  Future<void> _navigateToMap() async {
    // Prevent multiple taps
    if (_isNavigating) return;
    _isNavigating = true;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showError('Location services are disabled. Please enable them to use the map.');
          _isNavigating = false; // Reset flag
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _showError('Location permission denied. Please allow location access to use the map.');
          _isNavigating = false; // Reset flag
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Smooth navigation with fade animation
      await Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MapScreen(userLocation: position),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ));
    } catch (e) {
      _showError('Failed to get your location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _isNavigating = false; // Always reset the flag
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  // Add functionality methods for dashboard cards
  void _showSchedule() {
    // Prevent multiple taps
    if (_isNavigating) return;
    _isNavigating = true;
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ScheduleScreen()),
    ).then((_) => _isNavigating = false);
  }
  
  void _showInfo() {
    // Prevent multiple taps
    if (_isNavigating) return;
    _isNavigating = true;
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const InfoScreen()),
    ).then((_) => _isNavigating = false);
  }
  
  void _showSettings() {
    // Prevent multiple taps
    if (_isNavigating) return;
    _isNavigating = true;
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ).then((_) => _isNavigating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background pattern
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green[50]!,
                    Colors.white,
                  ],
                ),
              ),
            ),
            
            // Main content
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  SlideTransition(
                    position: _slideAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Waste Tracker",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Welcome message
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "Track your waste collection",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Service cards
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildServiceCard(
                            icon: Icons.local_shipping,
                            title: "Track Truck",
                            subtitle: "Real-time tracking",
                            onTap: _navigateToMap,
                          ),
                          _buildServiceCard(
                            icon: Icons.history,
                            title: "Schedule",
                            subtitle: "View schedules",
                            onTap: _showSchedule,
                          ),
                          _buildServiceCard(
                            icon: Icons.info,
                            title: "Info",
                            subtitle: "Learn more",
                            onTap: _showInfo,
                          ),
                          _buildServiceCard(
                            icon: Icons.settings,
                            title: "Settings",
                            subtitle: "App settings",
                            onTap: _showSettings,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Action button with smooth animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _navigateToMap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading 
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined),
                            SizedBox(width: 12),
                            Text(
                              "OPEN TRACKING MAP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.green[700],
                  size: 30,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}