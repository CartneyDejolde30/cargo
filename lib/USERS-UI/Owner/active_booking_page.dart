import 'package:flutter/material.dart';

class ActiveBookingsPage extends StatelessWidget {
  const ActiveBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Bookings"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Example active bookings
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading:
                  const Icon(Icons.assignment_turned_in, color: Colors.green),
              title: Text("Booking #${index + 1}"),
              subtitle: const Text("Car: Honda City\nDate: Nov 10–12, 2025"),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600),
                child: const Text("End Trip"),
              ),
            ),
          );
        },
      ),
    );
  }
}
