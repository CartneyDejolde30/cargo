import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Renter/widgets/bottom_nav_bar.dart';
import 'renters.dart';
import 'car_list_screen.dart';
import '../Renter/chats/chat_list_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedNavIndex = 2;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    // TODO: Replace with your actual API endpoint
    final String apiUrl = "http://192.168.1.11/carGOAdmin/api/get_notifications.php";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['status'] == 'success') {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(decoded['notifications']);
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching notifications: $e");
      // Use dummy data for demonstration
      _loadDummyData();
    }

    setState(() => _isLoading = false);
  }

  void _loadDummyData() {
    setState(() {
      _notifications = [
        {
          'id': '1',
          'title': 'Account Verified!',
          'message': 'Your account has been successfully verified. You can now onboard a car and have full access to all the features of the platform.',
          'date': 'Nov 13',
          'time': '05:08 PM',
          'isRead': false,
          'type': 'success',
        },
        {
          'id': '2',
          'title': 'Thank You for Your Verification Request! 👏',
          'message': 'We\'ll check this for you right away. Appreciate your patience!',
          'date': 'Nov 13',
          'time': '04:03 PM',
          'isRead': false,
          'type': 'info',
        },
      ];
    });
  }

  void _handleNavigation(int index) {
    setState(() => _selectedNavIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CarListScreen()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
        break;
      case 4:
        break;
    }
  }

  String _groupDateLabel(String date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Parse the notification date (assuming format like "Nov 13")
    // For simplicity, we'll just return the date as is
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you when something arrives",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Group notifications by date
    Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
    
    for (var notification in _notifications) {
      String date = notification['date'] ?? 'Unknown';
      if (!groupedNotifications.containsKey(date)) {
        groupedNotifications[date] = [];
      }
      groupedNotifications[date]!.add(notification);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: groupedNotifications.length,
      itemBuilder: (context, index) {
        String date = groupedNotifications.keys.elementAt(index);
        List<Map<String, dynamic>> notifications = groupedNotifications[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...notifications.map((notification) => _buildNotificationItem(notification)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'] ?? false;
    final String type = notification['type'] ?? 'info';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.grey.shade50,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification indicator and icon
            Column(
              children: [
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/app_icon.png', // Replace with your app icon
                      width: 30,
                      height: 30,
                      errorBuilder: (_, __, ___) => Icon(
                        type == 'success' ? Icons.check_circle : Icons.info,
                        color: type == 'success' ? Colors.green : Colors.blue,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? 'Notification',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        notification['time'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification['message'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}