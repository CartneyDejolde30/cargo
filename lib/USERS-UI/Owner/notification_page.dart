import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatefulWidget {
  final int userId;
  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  List notifications = [];
  Map<String, List> grouped = {};
  bool loading = true;
  bool hasError = false;
  String errorMessage = '';
  int lastCount = 0;
  Timer? timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    fetchNotifications();
    timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchNotifications(silent: true));
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    timer?.cancel();
    player.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) setState(() {
      loading = true;
      hasError = false;
    });

    final url = Uri.parse(
        "http://192.168.1.11/carGOAdmin/get_notification.php?user_id=${widget.userId}");

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newData = data["notifications"] ?? [];

        // 🔔 Detect new notifications
        if (newData.length > lastCount && silent && lastCount > 0) {
          await _playAlertSound();
          _vibrate();
        }

        lastCount = newData.length;

        setState(() {
          notifications = newData;
          _groupByDate();
          loading = false;
          hasError = false;
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      setState(() {
        loading = false;
        hasError = true;
        errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.toString().contains('Failed host lookup') || 
               error.toString().contains('Failed to fetch')) {
      return 'Cannot connect to server. Please check your network connection.';
    } else {
      return 'Unable to load notifications. Please try again.';
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await player.play(AssetSource("notification_sound.mp3"));
    } catch (_) {}
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 80);
    }
  }

  void _groupByDate() {
    grouped.clear();

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    for (var n in notifications) {
      try {
        final date = DateTime.parse(n["created_at"]);
        final formatted = DateFormat("yyyy-MM-dd").format(date);

        String label = "Earlier";
        if (formatted == DateFormat("yyyy-MM-dd").format(today)) label = "Today";
        if (formatted == DateFormat("yyyy-MM-dd").format(yesterday)) label = "Yesterday";

        grouped.putIfAbsent(label, () => []).add(n);
      } catch (e) {
        debugPrint("Error parsing date: $e");
      }
    }
  }

  Future<void> archive(int id) async {
    try {
      await http.post(
        Uri.parse("http://192.168.1.11/carGOAdmin/archive_notification.php"),
        body: {"id": id.toString()},
      ).timeout(const Duration(seconds: 10));

      setState(() {
        notifications.removeWhere((n) => n["id"] == id);
        _groupByDate();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.archive_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Notification archived',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error archiving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to archive notification'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> markAllRead() async {
    try {
      await http.post(
        Uri.parse("http://192.168.1.11/carGOAdmin/update_all.php"),
        body: {"user_id": widget.userId.toString()},
      ).timeout(const Duration(seconds: 10));
      
      fetchNotifications(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'All notifications marked as read',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error marking all read: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to mark notifications as read'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  String formatTime(String t) {
    try {
      return t.substring(11, 16);
    } catch (e) {
      return '';
    }
  }

  IconData _getNotificationIcon(String title) {
    if (title.toLowerCase().contains('booking') || title.toLowerCase().contains('request')) {
      return Icons.bookmark_outline;
    } else if (title.toLowerCase().contains('payment') || title.toLowerCase().contains('paid')) {
      return Icons.payment_outlined;
    } else if (title.toLowerCase().contains('confirm')) {
      return Icons.check_circle_outline;
    } else if (title.toLowerCase().contains('rental') || title.toLowerCase().contains('end')) {
      return Icons.event_available_outlined;
    } else if (title.toLowerCase().contains('cancel')) {
      return Icons.cancel_outlined;
    } else {
      return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String title) {
    if (title.toLowerCase().contains('booking') || title.toLowerCase().contains('request')) {
      return Colors.blue;
    } else if (title.toLowerCase().contains('payment')) {
      return Colors.green;
    } else if (title.toLowerCase().contains('confirm')) {
      return Colors.teal;
    } else if (title.toLowerCase().contains('cancel')) {
      return Colors.red;
    } else if (title.toLowerCase().contains('rental')) {
      return Colors.orange;
    } else {
      return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n["read_status"] == "unread").length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Notifications",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            if (unreadCount > 0)
              Text(
                "$unreadCount unread",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: markAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  "Mark all read",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.black),
                  const SizedBox(height: 16),
                  Text(
                    "Loading notifications...",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_off_outlined,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Connection Error",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => fetchNotifications(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            'Try Again',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : grouped.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "No notifications yet",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "We'll notify you when something arrives",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: fetchNotifications,
                        color: Colors.black,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: grouped.entries.map((section) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                                  child: Text(
                                    section.key,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                ...section.value.map((n) => _notificationItem(n)),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
    );
  }

  Widget _notificationItem(n) {
    final isUnread = n["read_status"] == "unread";
    final icon = _getNotificationIcon(n["title"] ?? "");
    final color = _getNotificationColor(n["title"] ?? "");

    return Dismissible(
      key: Key(n["id"].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.orange.shade700,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              "Archive",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => archive(n["id"]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? color.withOpacity(0.3) : Colors.grey.shade200,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnread 
                  ? color.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnread ? color.withOpacity(0.1) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isUnread ? color : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n["title"] ?? "Notification",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n["message"] ?? "",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatTime(n["created_at"] ?? ""),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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