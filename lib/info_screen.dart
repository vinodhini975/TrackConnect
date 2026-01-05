import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@wastetracker.com',
      queryParameters: {
        'subject': 'Support Request - Waste Tracker App',
      },
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch $emailLaunchUri');
      }
    } catch (e) {
      debugPrint("Could not launch email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info & Help'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How to use Waste Tracker",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "1. Check the collection schedule to know when to put out your waste.\n"
              "2. Use the 'Track Truck' feature to see real-time location of the collection truck.\n"
              "3. Ensure your location services are enabled for accurate tracking.\n"
              "4. Enable notifications to receive alerts when the truck is nearby.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const Divider(height: 40),
            const Text(
              "Waste Categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildCategoryItem(Icons.delete, "General Waste", "Non-recyclable materials"),
            _buildCategoryItem(Icons.recycling, "Recyclables", "Plastic, Paper, Glass"),
            _buildCategoryItem(Icons.eco, "Organic/Compost", "Food waste, garden trimmings"),
            const Divider(height: 40),
            const Text(
              "App Info",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const ListTile(
              title: Text("Version"),
              trailing: Text("1.0.0"),
            ),
            ListTile(
              title: const Text("Contact Support"),
              trailing: const Icon(Icons.email),
              onTap: _launchEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
    );
  }
}
