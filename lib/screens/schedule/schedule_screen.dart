import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../data/mock_data/mock_data_store.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection Timeline", style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final displayList = provider.schedule.isEmpty 
              ? MockDataStore.ward195Schedule 
              : provider.schedule;

          final String todayName = DateFormat('EEEE').format(DateTime.now());

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge, vertical: AppDimens.paddingMedium),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final item = displayList[index];
              final bool isToday = item.dayOfWeek.toLowerCase() == todayName.toLowerCase();
              final bool isLast = index == displayList.length - 1;

              return _buildTimelineItem(context, item, isToday, isLast);
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, dynamic item, bool isToday, bool isLast) {
    final bool isNoCollection = item.wasteType == "No Collection";

    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline Indicator
          Column(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isToday ? AppColors.primary : Colors.grey.shade300, 
                    width: 2
                  ),
                ),
                child: isToday 
                    ? const Center(child: Icon(Icons.check, size: 12, color: Colors.white))
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.paddingMedium),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                  border: Border.all(
                    color: isToday ? AppColors.primary.withOpacity(0.2) : const Color(0xFFF1F5F9),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isToday ? "TODAY" : item.dayOfWeek.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w900, 
                            color: isToday ? AppColors.primary : AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                        if (!isNoCollection)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.primary : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              isToday ? "READY" : "UPCOMING",
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.w800, 
                                color: isToday ? Colors.white : AppColors.primaryDark
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.wasteType,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    if (!isNoCollection) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            "${item.startTime} - ${item.endTime}",
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
