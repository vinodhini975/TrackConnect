import 'package:flutter/material.dart';
import 'models/driver_model.dart';

class TripDetailsScreen extends StatelessWidget {
  final Driver driver;

  const TripDetailsScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Trip Details"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Driver Summary Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF00C853),
                  child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(driver.phoneNumber, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("ON TRIP", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.route_rounded, color: Colors.grey),
                SizedBox(width: 8),
                Text("ROUTE SCHEDULE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Timeline List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: driver.route.length,
              itemBuilder: (context, index) {
                final stop = driver.route[index];
                final bool isPassed = index <= driver.currentStopIndex;
                final bool isCurrent = index == driver.currentStopIndex;

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      // Timeline Indicator
                      Column(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPassed ? const Color(0xFF00C853) : Colors.grey.shade300,
                              border: isCurrent ? Border.all(color: const Color(0xFF00C853), width: 4) : null,
                            ),
                            child: isPassed && !isCurrent ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                          ),
                          if (index < driver.route.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isPassed ? const Color(0xFF00C853) : Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Stop Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.area,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                  color: isPassed ? Colors.black : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Scheduled: ${stop.time}",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                              if (isCurrent)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text("Current Stop - Arriving soon", style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
