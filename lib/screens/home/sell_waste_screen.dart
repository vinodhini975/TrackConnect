import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';

class SellWasteScreen extends StatefulWidget {
  const SellWasteScreen({super.key});

  @override
  State<SellWasteScreen> createState() => _SellWasteScreenState();
}

class _SellWasteScreenState extends State<SellWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Plastic';
  double _estimatedWeight = 1.0;
  bool _isLoadingLocation = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Plastic', 'icon': Icons.local_drink_rounded, 'points': 50},
    {'name': 'Paper', 'icon': Icons.description_rounded, 'points': 30},
    {'name': 'Metal', 'icon': Icons.build_rounded, 'points': 100},
    {'name': 'Glass', 'icon': Icons.wine_bar_rounded, 'points': 40},
    {'name': 'E-Waste', 'icon': Icons.devices_rounded, 'points': 200},
    {'name': 'Cardboard', 'icon': Icons.archive_rounded, 'points': 25},
  ];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _locationController.text = "${place.street}, ${place.subLocality}, ${place.locality}";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GPS error. Please type manually.")));
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    final int potentialPoints = (_categories.firstWhere((c) => c['name'] == _selectedCategory)['points'] as int) * _estimatedWeight.toInt();

    final Email email = Email(
      body: """
Request Type: SELL WASTE / PICKUP
Resident: ${user?.fullName}
Ward: ${user?.wardNumber}

Waste Category: $_selectedCategory
Estimated Weight: $_estimatedWeight kg
Potential Points: $potentialPoints

Pickup Location: ${_locationController.text}
""",
      subject: 'Pickup Request: $_selectedCategory - ${user?.fullName}',
      recipients: ['sridevisridevij1@gmail.com'],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pickup Request Sent!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sellAndEarn, style: TextStyle(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPointsEstimate(),
              const SizedBox(height: 32),
              const Text(AppStrings.selectWasteType, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildCategoryGrid(),
              const SizedBox(height: 32),
              const Text(AppStrings.estimatedWeight, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildWeightSlider(),
              const SizedBox(height: 32),
              const Text(AppStrings.pickupLocation, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: "Where should we pick it up?",
                  suffixIcon: IconButton(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Please provide location" : null,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text(AppStrings.requestPickup, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsEstimate() {
    final cat = _categories.firstWhere((c) => c['name'] == _selectedCategory);
    final int points = (cat['points'] as int) * _estimatedWeight.toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ESTIMATED EARNING", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text("$points Eco-Points", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final bool isSelected = _selectedCategory == cat['name'];
        return InkWell(
          onTap: () => setState(() => _selectedCategory = cat['name']),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'], color: isSelected ? AppColors.primary : Colors.grey, size: 28),
                const SizedBox(height: 8),
                Text(cat['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? AppColors.primaryDark : Colors.black87)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeightSlider() {
    return Column(
      children: [
        Slider(
          value: _estimatedWeight,
          min: 1, max: 50,
          divisions: 49,
          activeColor: AppColors.primary,
          label: "${_estimatedWeight.toInt()} kg",
          onChanged: (v) => setState(() => _estimatedWeight = v),
        ),
        Text("${_estimatedWeight.toInt()} kg", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primaryDark)),
      ],
    );
  }
}
