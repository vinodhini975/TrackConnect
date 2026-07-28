import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintController = TextEditingController();
  final _locationController = TextEditingController();
  File? _selectedMedia;
  bool _isImage = true;
  bool _isLoadingLocation = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _complaintController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final XFile? media = isVideo 
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);
    
    if (media != null) {
      setState(() {
        _selectedMedia = File(media.path);
        _isImage = !isVideo;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _locationController.text = "${place.street}, ${place.subLocality}, ${place.locality} - ${place.postalCode}";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not fetch GPS location. Please enter manually.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    final String recipient = "sridevisridevij1@gmail.com";
    
    final String body = """
Name: ${user?.fullName ?? 'Resident'}
Email: ${user?.email ?? 'Not Provided'}
Ward: ${user?.wardNumber ?? 'Not Provided'}

Location: ${_locationController.text}

Complaint Details:
${_complaintController.text}

--
Sent via TrackConnect
""";

    final Email email = Email(
      body: body,
      subject: 'Waste Management Report - ${user?.fullName ?? 'Resident'}',
      recipients: [recipient],
      attachmentPaths: _selectedMedia != null ? [_selectedMedia!.path] : [],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email client opened with attachments.")),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not send mail: $error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue", style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("What is the issue?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _complaintController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "e.g. Garbage not collected since 2 days...",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Please describe the issue" : null,
              ),
              const SizedBox(height: 24),
              const Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: "Enter address manually or use GPS",
                  suffixIcon: IconButton(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Please provide location" : null,
              ),
              const SizedBox(height: 24),
              const Text("Evidence (Photo/Video)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildMediaPicker(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
                  ),
                  child: const Text("SEND REPORT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPicker() {
    return Column(
      children: [
        if (_selectedMedia != null)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              image: _isImage 
                  ? DecorationImage(image: FileImage(_selectedMedia!), fit: BoxFit.cover)
                  : null,
              color: Colors.black12,
            ),
            child: !_isImage 
                ? const Center(child: Icon(Icons.videocam, size: 48, color: Colors.white))
                : null,
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickMedia(ImageSource.camera, false),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text("Photo"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickMedia(ImageSource.camera, true),
                icon: const Icon(Icons.videocam_rounded),
                label: const Text("Video"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
