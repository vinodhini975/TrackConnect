import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import '../schedule/schedule_screen.dart';

class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("More", style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        children: [
          _buildUserBrief(context),
          const SizedBox(height: 24),
          _buildMenuTile(
            context, 
            "Full Schedule", 
            "Weekly routine & reminders", 
            Icons.calendar_month_rounded, 
            Colors.blue,
            const ScheduleScreen()
          ),
          const SizedBox(height: 16),
          _buildMenuTile(
            context, 
            "My Impact", 
            "Achievements & points", 
            Icons.bar_chart_rounded, 
            AppColors.primary,
            const ReportsScreen()
          ),
          const SizedBox(height: 16),
          _buildMenuTile(
            context, 
            "Settings & Profile", 
            "Address, Ward, Account", 
            Icons.person_rounded, 
            Colors.purple,
            const ProfileScreen()
          ),
          const SizedBox(height: 32),
          ListTile(
            onTap: () => context.read<AuthProvider>().logout(),
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildUserBrief(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? "Resident", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text(user?.wardNumber ?? "Ward 195", style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, String sub, IconData icon, Color color, Widget target) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
