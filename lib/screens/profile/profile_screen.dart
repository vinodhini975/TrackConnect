import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../data/mock_data/mock_data_store.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  String? _selectedWard;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _selectedWard = user?.wardNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final auth = context.read<AuthProvider>();
    if (_selectedWard == null) return;
    
    await auth.updateProfile(
      fullName: _nameController.text.trim(),
      wardNumber: _selectedWard!,
    );

    if (mounted) {
      if (auth.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileUpdated), backgroundColor: AppColors.primary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width > 900 ? size.width * 0.2 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context), 
            icon: const Icon(Icons.logout_rounded, color: AppColors.accentOrange)
          )
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) return const Center(child: Text("No user logged in."));

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 32),
                _buildSettingsSection(auth),
                const SizedBox(height: 40),
                _buildSupportSection(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.chipBackground,
                backgroundImage: user.profilePhotoUrl != null 
                    ? CachedNetworkImageProvider(user.profilePhotoUrl!)
                    : null,
                child: user.profilePhotoUrl == null 
                    ? const Icon(Icons.person_rounded, size: 60, color: AppColors.primary) 
                    : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(user.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }

  Widget _buildSettingsSection(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.accountDetails, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: AppStrings.fullName,
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedWard,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: AppStrings.selectWard,
              prefixIcon: Icon(Icons.map_outlined),
            ),
            items: MockDataStore.wardList.map((String ward) {
              return DropdownMenuItem<String>(
                value: ward,
                child: Text(ward, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) setState(() => _selectedWard = newValue);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _updateProfile,
              child: auth.isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text(AppStrings.updateProfile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildSupportItem(AppStrings.helpSupport, Icons.help_outline_rounded),
        const SizedBox(height: 12),
        _buildSupportItem(AppStrings.privacyPolicy, Icons.privacy_tip_outlined),
        const SizedBox(height: 12),
        _buildSupportItem(AppStrings.aboutApp, Icons.info_outline_rounded),
      ],
    );
  }

  Widget _buildSupportItem(String title, IconData icon) {
    return ListTile(
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.1))
      ),
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
