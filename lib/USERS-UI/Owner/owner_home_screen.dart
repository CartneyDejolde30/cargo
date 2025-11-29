import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.dart';
import 'mycar_page.dart';
import 'notification_page.dart';
import 'message_page.dart';
import 'profile_page.dart';

import 'package:flutter_application_1/USERS-UI/Owner/widgets/verify_popup.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _selectedIndex = 0;
  String ownerId = "";   // <-- FIX: Changed to String
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOwnerId();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VerifyPopup.showIfNotVerified(context);
    });
  }

  Future<void> loadOwnerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    ownerId = prefs.getString("user_id") ?? "";  // <-- FIXED

    print("OWNER ID LOADED → $ownerId");

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      DashboardPage(),
      MyCarPage(ownerId: int.tryParse(ownerId) ?? 0),
      NotificationPage(userId: int.tryParse(ownerId) ?? 0),
            // <-- FIX: Consistent type
      MessagePage(),
      ProfilePage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'My Car'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
