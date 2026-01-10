import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/glass_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String _selectedWard = "Default";
  bool _isLoading = false;

  final List<String> _shimoggaWards = [
    "Default",
    "Ward 1 - Gandhi Nagar",
    "Ward 2 - Tilak Nagar",
    "Ward 3 - Vinoba Nagar",
    "Ward 4 - Jayanagar",
    "Ward 5 - Vidyanagar",
    "Ward 6 - Durgigudi",
    "Ward 7 - Shimogga Rural",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? "";
      
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _nameController.text = doc.data()!['name'] ?? "";
            _selectedWard = doc.data()!['ward'] ?? "Default";
            
            // Ensure selected ward is valid in our current list
            if (!_shimoggaWards.contains(_selectedWard)) {
               _shimoggaWards.add(_selectedWard);
            }
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(), // Keep email synced
          'ward': _selectedWard,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated! Your tracker is now synced to this ward."))
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red)
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: Text('Edit Profile'),
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Hero(
                tag: 'profile_pic',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF00C853),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField("Full Name", _nameController, Icons.person),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                readOnly: true, // Email usually shouldn't be changed easily
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              _buildWardDropdown(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ) 
                      : const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWardDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedWard,
      decoration: InputDecoration(
        labelText: "Select Ward / Zone",
        prefixIcon: const Icon(Icons.map_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _shimoggaWards.map((String ward) {
        return DropdownMenuItem<String>(
          value: ward,
          child: Text(ward, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _selectedWard = newValue);
        }
      },
    );
  }
}
