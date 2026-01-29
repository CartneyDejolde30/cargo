import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../Renter/widgets/bottom_nav_bar.dart';

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
            "http://10.77.127.2/carGOAdmin/get_notification_renter.php?user_id=$_loadedUserId"),
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
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 80);
    }
  }

  // ---------------- GET ICON BY TYPE ---------------- //

  IconData _getIconByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.calendar_month_outlined;
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'alert':
        return Icons.info_outline;
      case 'success':
        return Icons.verified_outlined;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorByType(BuildContext context, String type) {
  return Theme.of(context).iconTheme.color!;
}


  Color _getBackgroundByType(BuildContext context, String type) {
  return Theme.of(context).colorScheme.surfaceVariant;
}


  // ---------------- MARK AS READ ---------------- //

  void _markAsRead(Map<String, dynamic> notification) {
    setState(() {
      notification["isRead"] = true;
    });
  }

  // ---------------- DELETE NOTIFICATION ---------------- //

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Delete Notification",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this notification?",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _notifications.remove(notification);
        _groupByDate();
      });

      // Optional: Make API call to delete from backend
      // await _deleteFromBackend(notification["id"]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Notification deleted",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Theme.of(context).iconTheme.color,







            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ---------------- OPEN NOTIFICATION DETAIL ---------------- //

  void _openNotificationDetail(Map<String, dynamic> notification) {
    _markAsRead(notification);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notification: notification,
          onDelete: () {
            Navigator.of(context).pop();
            _deleteNotification(notification);
          },
        ),
      ),
    );
  }

  // ---------------- UI ---------------- //

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n["isRead"]).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,



            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty && unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n["isRead"] = true;
                  }
                });
              },
              child: Text(
                "Mark all read",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).iconTheme.color,

                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ?  Center(child: CircularProgressIndicator(
  color: Theme.of(context).colorScheme.primary,
)
)
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.outline,            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No notifications yet",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).iconTheme.color,



            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      color: Theme.of(context).iconTheme.color,



      onRefresh: _loadInitialNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          String date = grouped.keys.elementAt(index);
          List<Map<String, dynamic>> list = grouped[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ...list.map((n) => _buildNotificationItem(n)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> n) {
    final type = n["type"] ?? "info";
    final iconColor = _getColorByType(context, type);

    final backgroundColor = _getBackgroundByType(context, type);

    final icon = _getIconByType(type);
    final isRead = n["isRead"] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
          ? Theme.of(context).colorScheme.outlineVariant
          : Theme.of(context).colorScheme.primary.withOpacity(0.3),

          width: isRead ? 1 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openNotificationDetail(n),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n["title"],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Theme.of(context).iconTheme.color,



                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration:  BoxDecoration(
                              color: Theme.of(context).iconTheme.color,



                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n["message"],
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,),
                          const SizedBox(width: 4),
                          Text(
                            n["time"],
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.outline,fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteNotification(n),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.outline,                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(int index) {}
}

// ---------------- NOTIFICATION DETAIL SCREEN ---------------- //

class NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDelete;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    required this.onDelete,
  });

  IconData _getIconByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.calendar_month_outlined;
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'alert':
        return Icons.info_outline;
      case 'success':
        return Icons.verified_outlined;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getBackgroundByType(BuildContext context, String type) {
  return Theme.of(context).colorScheme.surfaceVariant;
}


  @override
  Widget build(BuildContext context) {
    final type = notification["type"] ?? "info";
    final icon = _getIconByType(type);
    final backgroundColor = _getBackgroundByType(context, type);


    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),

          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).iconTheme.color),

            onPressed: onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).iconTheme.color,



                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              notification["title"],
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).iconTheme.color,



                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,                ),
                const SizedBox(width: 6),
                Text(
                  "${notification["date"]} • ${notification["time"]}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,                
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                notification["message"],
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}