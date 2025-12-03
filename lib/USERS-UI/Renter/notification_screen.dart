import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../Renter/widgets/bottom_nav_bar.dart';
import 'renters.dart';
import 'car_list_screen.dart';
import '../Renter/chats/chat_list_screen.dart';

class NotificationScreen extends StatefulWidget {
  final int userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedNavIndex = 2;

  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  Map<String, List<Map<String, dynamic>>> grouped = {};

  final AudioPlayer player = AudioPlayer();
  int? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _listenToFCM();
  }

  // ---------------- LOAD USER_ID ---------------- //

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();

    // Try SharedPreferences first
    final savedId = prefs.getString("user_id");

    if (savedId != null) {
      _loadedUserId = int.tryParse(savedId);
    }

    // Fallback to widget.userId
    _loadedUserId ??= widget.userId;

    print("🔥 Loaded user_id: $_loadedUserId");

    _loadInitialNotifications();
  }

  // ---------------- LOAD NOTIFICATIONS ---------------- //

  Future<void> _loadInitialNotifications() async {
    if (_loadedUserId == null) {
      print("❌ user_id is NULL");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
            "http://10.72.15.180/carGOAdmin/get_notification_renter.php?user_id=$_loadedUserId"),
      );

      print("📩 RAW RESPONSE: ${res.body}");

      final decoded = jsonDecode(res.body);

      if (decoded is! Map || decoded["status"] != "success") {
        setState(() {
          _notifications = [];
          grouped.clear();
          _isLoading = false;
        });
        return;
      }

      final rawList = decoded["notifications"];
      final List<Map<String, dynamic>> safeList =
          (rawList is List) ? List<Map<String, dynamic>>.from(rawList) : [];

      setState(() {
        _notifications = safeList;
        _groupByDate();
        _isLoading = false;
      });
    } catch (e) {
      print("❌ ERROR: $e");

      setState(() {
        _notifications = [];
        grouped.clear();
        _isLoading = false;
      });
    }
  }

  // ---------------- REALTIME FCM LISTENER ---------------- //

  void _listenToFCM() {
    FirebaseMessaging.onMessage.listen((message) {
      _playSound();
      _vibrate();

      Map<String, dynamic> newNotif = {
        "id": message.data["id"],
        "title": message.notification?.title ?? "Notification",
        "message": message.notification?.body ?? "",
        "date": message.data["date"] ?? "Today",
        "time": message.data["time"] ?? "",
        "type": message.data["type"] ?? "info",
        "isRead": false
      };

      setState(() {
        _notifications.insert(0, newNotif);
        _groupByDate();
      });
    });
  }

  // ---------------- GROUP BY DATE ---------------- //

  void _groupByDate() {
    grouped.clear();

    for (var n in _notifications) {
      String date = n["date"] ?? "Unknown";

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }

      grouped[date]!.add(n);
    }
  }

  // ---------------- SOUND + VIBRATE ---------------- //

  Future<void> _playSound() async {
    await player.play(AssetSource("notification_sound.mp3"));
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 80);
    }
  }

  // ---------------- UI (UNCHANGED) ---------------- //

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
          : grouped.isEmpty
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
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        String date = grouped.keys.elementAt(index);
        List<Map<String, dynamic>> list = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                date,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
            ...list.map((n) => _buildNotificationItem(n)),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: n["isRead"] ? Colors.white : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!n["isRead"])
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n["title"],
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    n["message"],
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              n["time"],
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {}
}
