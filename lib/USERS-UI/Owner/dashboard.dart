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
    loadName();
  }

  Future<void> loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userName = prefs.getString("fullname") ?? "User";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Clean Light Header Style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 55, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withAlpha((0.05 * 255).round()),
                    offset: const Offset(0, 3),
                  )
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "CarGo",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade100,
                        child: Image.asset("assets/cargo.png", width: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Welcome back 👋",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 Stats Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                "Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: const [
                  StatCard(icon: Icons.wallet, title: "Total Income", value: "₱120,000"),
                  StatCard(icon: Icons.calendar_month, title: "Monthly", value: "₱15,000"),
                  StatCard(icon: Icons.timeline, title: "Weekly", value: "₱4,000"),
                  StatCard(icon: Icons.directions_car, title: "Cars", value: "6"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Actions Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                "Actions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  ActionButton(
                    title: "Pending Requests",
                    count: 2,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFb58900),
                        Color(0xFF8b6f00),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PendingRequestsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  ActionButton(
                    title: "Active Bookings",
                    count: 3,
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveBookingsPage()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // Reduced space since no bottom nav here
          ],
        ),
      ),
      // NO BOTTOM NAVIGATION BAR - It's in OwnerHomeScreen
    );
  }
}

// ==================== COMPONENTS ====================

class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;

  const StatCard({
    required this.title, 
    required this.value, 
    required this.icon, 
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.grey.shade100,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.blueAccent),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 14, 
              color: Colors.grey.shade700, 
              fontWeight: FontWeight.w600
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String title;
  final int count;
  final Gradient gradient;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.title,
    required this.count,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 17, 
                fontWeight: FontWeight.bold
              )
            ),
            Text(
              "$count", 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 20, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}