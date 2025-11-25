import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

class NotificationPage extends StatefulWidget {
  final int userId;

  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  int unreadCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    print("🔥 USER ID IS: ${widget.userId}");
    print("🌍 REQUEST URL: http://10.72.15.180/carGOAdmin/get_notification.php?user_id=${widget.userId}");

    final url = Uri.parse(
      "http://10.72.15.180/carGOAdmin/get_notification.php?user_id=${widget.userId}"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        notifications = data["notifications"];
        unreadCount = data["unread_count"];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> markAsRead(int id) async {
    await http.post(
      Uri.parse("http://10.72.15.180/carGOAdmin/update_notification.php"),
      body: {"id": id.toString()},
    );
    fetchNotifications();
  }

  Future<void> deleteNotification(int id) async {
    await http.post(
      Uri.parse("http://10.72.15.180/carGOAdmin/delete_notification.php"),
      body: {"id": id.toString()},
    );
    fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text("Notifications", style: TextStyle(color: Colors.white)),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];

                    return Dismissible(
                      key: Key(n["id"].toString()),
                      background: Container(
                        color: Colors.red.shade700,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        deleteNotification(n["id"]);
                      },

                      child: GestureDetector(
                        onTap: () async {
                          // Fixed: removed ?? false since hasVibrator() never returns null
                          if (await Vibration.hasVibrator()) {
                            Vibration.vibrate(duration: 50);
                          }
                          markAsRead(n["id"]);
                        },

                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: n["read_status"] == "unread"
                                  ? Colors.black
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(10),

                          child: ListTile(
                            title: Text(
                              n["title"],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                decoration: n["read_status"] == "read"
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              n["message"],
                              style: const TextStyle(color: Colors.black87),
                            ),
                            trailing: Text(
                              n["created_at"].toString().substring(0, 16),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}