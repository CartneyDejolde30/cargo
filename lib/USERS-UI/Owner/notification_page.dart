import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';

class NotificationPage extends StatefulWidget {
  final int userId;
  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  Map<String, List> grouped = {};
  bool loading = true;
  int lastCount = 0;
  Timer? timer;

  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchNotifications(silent: true));
  }

  @override
  void dispose() {
    timer?.cancel();
    player.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) setState(() => loading = true);

    final url = Uri.parse(
        "http://10.72.15.180/carGOAdmin/get_notification.php?user_id=${widget.userId}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newData = data["notifications"] ?? [];

        // 🔔 Detect new notifications
        if (newData.length > lastCount && silent) {
          await _playAlertSound();
          _vibrate();
        }

        lastCount = newData.length;

        setState(() {
          notifications = newData;
          _groupByDate();
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      setState(() => loading = false);
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
      final date = DateTime.parse(n["created_at"]);
      final formatted = DateFormat("yyyy-MM-dd").format(date);

      String label = "Earlier";
      if (formatted == DateFormat("yyyy-MM-dd").format(today)) label = "Today";
      if (formatted == DateFormat("yyyy-MM-dd").format(yesterday)) label = "Yesterday";

      grouped.putIfAbsent(label, () => []).add(n);
    }
  }

  Future<void> archive(int id) async {
    await http.post(
      Uri.parse("http://10.72.15.180/carGOAdmin/archive_notification.php"),
      body: {"id": id.toString()},
    );

    setState(() {
      notifications.removeWhere((n) => n["id"] == id);
      _groupByDate();
    });
  }

  Future<void> markAllRead() async {
    await http.post(
      Uri.parse("http://10.72.15.180/carGOAdmin/update_all.php"),
      body: {"user_id": widget.userId.toString()},
    );
    fetchNotifications(silent: true);
  }

  String formatTime(String t) => t.substring(11, 16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.done_all, color: Colors.black),
              onPressed: markAllRead),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : grouped.isEmpty
              ? const Center(child: Text("No notifications yet"))
              : RefreshIndicator(
                  onRefresh: fetchNotifications,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: grouped.entries.map((section) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(section.key,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          ...section.value.map((n) => _notificationItem(n)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  Widget _notificationItem(n) {
    return Dismissible(
      key: Key(n["id"].toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.orange.shade700,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      onDismissed: (_) => archive(n["id"]),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: n["read_status"] == "unread" ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
               color: Colors.black.withAlpha((0.08 * 255).round()),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n["title"], style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(n["message"], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(formatTime(n["created_at"]),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          ],
        ),
      ),
    );
  }
}
