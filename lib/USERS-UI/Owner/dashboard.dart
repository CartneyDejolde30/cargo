import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pending_request_page.dart';
import 'active_booking_page.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("fullname") ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "CarGo",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Image.asset(
                    "assets/cargo.png",
                    width: 45,
                    height: 45,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome, $userName 👋",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // ===== DASHBOARD CARDS =====
              Row(
                children: const [
                  DashboardCard(title: "Total Income", value: "₱120,000"),
                  SizedBox(width: 10),
                  DashboardCard(title: "Monthly Income", value: "₱15,000"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  DashboardCard(title: "Weekly Income", value: "₱4,000"),
                  SizedBox(width: 10),
                  DashboardCard(title: "Total Cars", value: "6"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  DashboardCard(title: "Available Cars", value: "4"),
                  SizedBox(width: 10),
                  Expanded(child: SizedBox()), // Keeps row aligned
                ],
              ),
              const SizedBox(height: 25),

              // ===== BUTTONS =====
              DashboardButton(
                title: "Pending Requests",
                value: "2",
                color: Colors.amber.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PendingRequestsPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              DashboardButton(
                title: "Active Bookings",
                value: "3",
                color: Colors.green.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveBookingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== REUSABLE WIDGETS =====

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;

  const DashboardCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const DashboardButton({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
