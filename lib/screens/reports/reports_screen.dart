import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../data/mock_data/mock_data_store.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/loading_shimmer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ReportsProvider>().loadReports(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width > 900 ? size.width * 0.2 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.reports),
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  LoadingShimmer(),
                  SizedBox(height: 20),
                  LoadingShimmer(),
                ],
              ),
            );
          }

          // Use Mock report if DB is empty
          final report = provider.report ?? MockDataStore.report;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPointsOverview(report),
                const SizedBox(height: 32),
                const Text(
                  AppStrings.ecoImpact,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _buildImpactGrid(size.width, report),
                const SizedBox(height: 32),
                const Text(
                  AppStrings.weeklyConsistency,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _buildConsistencyChart(report),
                const SizedBox(height: 32),
                const Text(
                  AppStrings.ecoBadges,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _buildBadgesSection(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsOverview(dynamic report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text("Total Eco-Points", style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            "${report.totalEcoPoints}",
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              report.level,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactGrid(double screenWidth, dynamic report) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: screenWidth < 350 ? 1 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: screenWidth < 350 ? 2.5 : 1.2,
      children: [
        _buildImpactCard("Waste Saved", "${report.wasteSavedKg} kg", Icons.delete_sweep_rounded, Colors.blue),
        _buildImpactCard("CO2 Saved", "${report.co2SavedKg} kg", Icons.cloud_done_rounded, Colors.green),
        _buildImpactCard("Recycled", "${report.recycledKg} kg", Icons.recycling_rounded, Colors.orange),
        _buildImpactCard("Trees Offset", "${report.treesEquivalent}", Icons.park_rounded, Colors.teal),
      ],
    );
  }

  Widget _buildImpactCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildConsistencyChart(dynamic report) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final consistency = report.weeklyConsistency;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final isCheck = consistency[index];
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCheck ? AppColors.primary : AppColors.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCheck ? Icons.check_rounded : Icons.close_rounded,
                    color: isCheck ? Colors.white : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(days[index], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBadgesSection() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildBadgeItem("Early Bird", Icons.wb_twilight_rounded, Colors.orange),
          _buildBadgeItem("Recycler", Icons.reorder_rounded, Colors.blue),
          _buildBadgeItem("Master", Icons.workspace_premium_rounded, Colors.purple),
          _buildBadgeItem("Greenie", Icons.forest_rounded, Colors.green),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(String name, IconData icon, Color color) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
