import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/truck_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimens.dart';
import 'complaint_screen.dart';
import 'sell_waste_screen.dart';
import '../schedule/schedule_screen.dart';
import '../reports/reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context),
                  const SizedBox(height: 24),
                  _buildHeroETA(context),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildEcoTip(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: const Text(
        AppStrings.appName,
        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
          },
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, ${user?.fullName.split(' ')[0] ?? 'Resident'}!",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          AppStrings.tagline,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildHeroETA(BuildContext context) {
    return Consumer<TruckProvider>(
      builder: (context, provider, _) {
        final truck = provider.truckLocation;
        final bool isActive = truck != null && truck.isActive;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimens.radiusExtraLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? "${truck.etaMinutes} MINS" : "STAY READY",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          isActive ? "Until arrival at your door" : "No active trip in your ward",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 48),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<NavigationProvider>().setIndex(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar_rounded),
                      SizedBox(width: 12),
                      Text("TRACK LIVE", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1, 
          children: [
            _buildActionCard(
              context, 
              "Sell & Earn", 
              Icons.currency_rupee_rounded, 
              Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellWasteScreen())),
            ),
            _buildActionCard(
              context, 
              "Report Missed", 
              Icons.report_problem_rounded, 
              Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen())),
            ),
            _buildActionCard(
              context, 
              "Full Schedule", 
              Icons.calendar_today_rounded, 
              Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
            ),
            _buildActionCard(
              context, 
              "My Impact", 
              Icons.bar_chart_rounded, 
              AppColors.primary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
            _buildActionCard(
              context, 
              "Support", 
              Icons.support_agent_rounded, 
              Colors.purple,
              onTap: () {
                launchUrl(Uri.parse("mailto:sridevisridevij1@gmail.com?subject=Support Request"));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcoTip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      child: const Row(
        children: [
          Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Eco Tip", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  "Rinse plastic containers before recycling to avoid contamination.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
