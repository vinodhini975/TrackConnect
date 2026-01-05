import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Mock data that we can delete
  final List<Map<String, dynamic>> _notifications = [
    {
      "title": "Truck Arriving Soon",
      "body": "The waste collection truck is 1km away.",
      "time": "2m ago",
      "read": false,
    },
    {
      "title": "Waste Collected",
      "body": "Your waste has been collected successfully yesterday.",
      "time": "1d ago",
      "read": true,
    },
    {
      "title": "Schedule Change",
      "body": "No collection on public holiday next week.",
      "time": "2d ago",
      "read": true,
    },
    {
      "title": "Welcome",
      "body": "Welcome to Waste Tracker! Set up your profile.",
      "time": "1w ago",
      "read": true,
    },
  ];

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification deleted"), duration: Duration(seconds: 1)),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notification"),
        content: const Text("Are you sure you want to delete this notification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNotification(index);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _notifications.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No notifications", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.notifications, color: theme.primaryColor),
                    ),
                    title: Text(
                      notification['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(notification['body']),
                    ),
                    trailing: Text(
                      notification['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onLongPress: () => _confirmDelete(index),
                  ),
                );
              },
            ),
    );
  }
}
