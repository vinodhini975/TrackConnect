import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'main.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'widgets/glass_app_bar.dart';
import 'auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _locationAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check Notification Permission
    var notificationStatus = await Permission.notification.status;
    
    // Check Location Permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    bool locationGranted = serviceEnabled && 
        (permission == LocationPermission.always || permission == LocationPermission.whileInUse);

    if (mounted) {
      setState(() {
        _notificationsEnabled = notificationStatus.isGranted;
        _locationAccess = locationGranted;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      var status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _notificationsEnabled = true);
      } else if (status.isPermanentlyDenied) {
        _showSettingsDialog("Notification Permission", "Notifications are permanently denied. Please enable them in settings.");
        setState(() => _notificationsEnabled = false);
      } else {
        setState(() => _notificationsEnabled = false);
      }
    } else {
      // Cannot disable permissions programmatically on Android/iOS
      _showSettingsDialog("Disable Notifications", "To disable notifications, please go to App Settings.");
      setState(() => _notificationsEnabled = true); // Revert switch
    }
  }

  Future<void> _handleLocationToggle(bool value) async {
    if (value) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
             setState(() => _locationAccess = false);
             return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationAccess = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showSettingsDialog("Location Permission", "Location permission is permanently denied. Please enable it in settings.");
         setState(() => _locationAccess = false);
         return;
      }
      
      setState(() => _locationAccess = true);
    } else {
       // Cannot disable permissions programmatically
       _showSettingsDialog("Disable Location", "To disable location access, please go to App Settings.");
       setState(() => _locationAccess = true); // Revert switch
    }
  }

  void _showSettingsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const GlassAppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildSectionHeader("Preferences"),
          SwitchListTile(
            title: const Text("Notifications"),
            subtitle: const Text("Receive alerts when truck is nearby"),
            value: _notificationsEnabled,
            activeColor: Colors.green,
            onChanged: _handleNotificationToggle,
          ),
          const Divider(),
          _buildSectionHeader("Privacy & Permissions"),
          SwitchListTile(
            title: const Text("Location Access"),
            subtitle: const Text("Allow app to access your location"),
            value: _locationAccess,
            activeColor: Colors.green,
            onChanged: _handleLocationToggle,
          ),
          const Divider(),
          _buildSectionHeader("Account"),
          ListTile(
            title: const Text("Edit Profile"),
            subtitle: const Text("Name, Ward, & Settings"),
            leading: const Icon(Icons.person, color: Colors.blue),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
               Navigator.push(
                 context, 
                 PageRouteBuilder(
                   pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                   transitionsBuilder: (context, animation, secondaryAnimation, child) {
                     const begin = Offset(1.0, 0.0);
                     const end = Offset.zero;
                     const curve = Curves.easeInOut;
                     var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                     var offsetAnimation = animation.drive(tween);
                     return SlideTransition(position: offsetAnimation, child: child);
                   },
                 )
               );
            },
          ),
          ListTile(
            title: const Text("Log Out"),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () {
               _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.green.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              
              await AuthService().signOut(); // Perform actual sign out
              
              // Pop all screens to return to the root (which will be LoginScreen via StreamBuilder)
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
