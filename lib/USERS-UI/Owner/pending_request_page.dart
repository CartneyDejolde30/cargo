import 'package:flutter/material.dart';

class PendingRequestsPage extends StatelessWidget {
  const PendingRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Requests"),
        backgroundColor: Colors.amber,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Example number of requests
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.amber),
              title: Text("Request #${index + 1}"),
              subtitle: const Text("Car: Toyota Vios\nDate: Nov 11, 2025"),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600),
                child: const Text("Approve"),
              ),
            ),
          );
        },
      ),
    );
  }
}
