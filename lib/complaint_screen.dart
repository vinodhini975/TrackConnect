import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/glass_app_bar.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _complaintController = TextEditingController();
  bool _isLoading = false;
  Position? _currentPosition;
  String? _currentAddress;
  String _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchLocationAndAddress();
  }

  Future<void> _fetchLocationAndAddress() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        // Fetch actual address
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _currentAddress = "${place.street}, ${place.locality}, ${place.postalCode}";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching location/address: $e");
    }
  }

  Future<void> _submitComplaint() async {
    if (_complaintController.text.isEmpty) {
      _showWarning('Please describe the issue');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final senderEmail = user?.email ?? "kambamdeepak01@gmail.com";
      
      // Prepare Email Intent Data (Bypassing Firestore as requested)
      final String subject = 'Waste Track Complaint: $_currentTime';
      final String body = '--- WASTE TRACK COMPLAINT REPORT ---\n\n'
          'USER DETAILS:\n'
          'Email: $senderEmail\n'
          'UserID: ${user?.uid ?? "N/A"}\n\n'
          'INCIDENT DETAILS:\n'
          'Time: $_currentTime\n'
          'Address: ${_currentAddress ?? "Unknown Address"}\n'
          'Coordinates: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}\n\n'
          'DESCRIPTION:\n'
          '${_complaintController.text}\n\n'
          '--- END OF REPORT ---';

      final String rawUrl = 'mailto:support@trackconnect.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      final Uri emailUri = Uri.parse(rawUrl);

      // Try to launch. Note: canLaunchUrl sometimes returns false on Android 30+ 
      // even if queries are present, so we try-catch the launch directly.
      try {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSuccess();
          Navigator.pop(context); 
        }
      } catch (e) {
        debugPrint("Error launching email: $e");
        if (mounted) {
          _showError('No email app found. Please send to support@trackconnect.com manually.');
        }
      }
    } catch (e) {
      if (mounted) _showError('Failed to open mail app. Please check your email settings.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Complaint submitted successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    Navigator.pop(context);
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: Text('File a Complaint'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report an Issue',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve our service by reporting problems.',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            
            _buildSection(
              title: 'Description',
              child: TextField(
                controller: _complaintController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'What happened? (e.g., Missed pickup, Spillage...)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              title: 'Auto-Captured Details',
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.access_time_filled_rounded, 'Time', _currentTime),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.location_on_rounded, 
                      'GPS', 
                      _currentPosition != null 
                          ? '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}'
                          : 'Fetching GPS...',
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.home_work_rounded, 
                      'Actual Address', 
                      _currentAddress ?? 'Determining address...',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Submit Complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
