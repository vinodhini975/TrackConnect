import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/glass_app_bar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Track reminder state for 7 days
  final List<bool> _reminders = List.generate(7, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: Text('Collection Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDaySchedule(0, "Monday", "Waste Collection", "08:00 AM - 10:00 AM", true),
          _buildDaySchedule(1, "Tuesday", "Recycling", "09:00 AM - 11:00 AM", false),
          _buildDaySchedule(2, "Wednesday", "No Collection", "-", false),
          _buildDaySchedule(3, "Thursday", "Waste Collection", "08:00 AM - 10:00 AM", false),
          _buildDaySchedule(4, "Friday", "Compost", "07:00 AM - 09:00 AM", false),
          _buildDaySchedule(5, "Saturday", "No Collection", "-", false),
          _buildDaySchedule(6, "Sunday", "No Collection", "-", false),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(int index, String day, String type, String time, bool isToday) {
    bool hasReminder = _reminders[index];
    bool noCollection = type == "No Collection";

    return Card(
      color: isToday ? Colors.green.shade50 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isToday ? Colors.green : Colors.grey.shade300,
          child: Text(
            day.substring(0, 1),
            style: TextStyle(
                color: isToday ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          day,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isToday ? Colors.green.shade800 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(time, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToday)
              const Chip(
                label: Text("Today", style: TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.green,
              ),
            if (!noCollection)
            IconButton(
              icon: Icon(
                hasReminder ? Icons.notifications_active : Icons.notifications_none, 
                color: hasReminder ? Colors.green : Colors.grey
              ),
              onPressed: () {
                setState(() {
                  _reminders[index] = !_reminders[index];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(hasReminder ? "Reminder removed" : "Reminder set for $day"),
                    duration: const Duration(seconds: 1),
                  )
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
