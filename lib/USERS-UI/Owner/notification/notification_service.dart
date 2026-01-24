import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../Owner/mycar/api_constants.dart';
import './notification_model.dart';

class NotificationService {
  // Root (for get_notification.php in carGOAdmin/)
  static String get _rootBase => ApiConstants.baseUrl;

  // API folder (for actions inside /api/notifications/)
  static String get _apiBase =>
      "${ApiConstants.baseUrl}/api/notifications";

  /* ---------------- FETCH ALL NOTIFICATIONS ---------------- */
  Future<List<NotificationModel>> fetchNotifications(int userId) async {
    try {
      final url =
          Uri.parse("$_rootBase/get_notification.php?user_id=$userId");

      debugPrint("📡 Fetching notifications: $url");

      final response =
          await http.get(url).timeout(ApiConstants.apiTimeout);

      debugPrint("📥 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['notifications'] is List) {
          return (data['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      } else {
        debugPrint("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching notifications: $e");
    }

    return [];
  }

  /* ---------------- DELETE NOTIFICATION ---------------- */
  Future<bool> deleteNotification(int notificationId, int userId) async {
    try {
      final url = Uri.parse("$_apiBase/delete_notification.php");

      debugPrint("📡 Delete notification: $url");

      final response = await http
          .post(url, body: {
            'notification_id': notificationId.toString(),
            'user_id': userId.toString(),
          })
          .timeout(ApiConstants.apiTimeout);

      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint("❌ Error deleting notification: $e");
    }

    return false;
  }

  /* ---------------- ARCHIVE NOTIFICATION ---------------- */
  Future<bool> archiveNotification(int notificationId) async {
    try {
      final url = Uri.parse("$_apiBase/archive_notification.php");

      debugPrint("📡 Archive notification: $url");

      final response = await http
          .post(url, body: {
            'id': notificationId.toString(),
          })
          .timeout(ApiConstants.apiTimeout);

      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint("❌ Error archiving notification: $e");
    }

    return false;
  }

  /* ---------------- MARK AS READ ---------------- */
  Future<bool> markAsRead(String notificationId) async {
    try {
      final url = Uri.parse(
          "${ApiConstants.baseUrl}/api/mark_notification_read.php");

      debugPrint("📡 Mark as read: $url");

      final response = await http
          .post(url, body: {
            'notification_id': notificationId,
          })
          .timeout(ApiConstants.apiTimeout);

      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint("❌ Error marking notification as read: $e");
    }

    return false;
  }

  /* ---------------- FETCH UNREAD COUNT ---------------- */
  Future<Map<String, int>> fetchUnreadCounts(String userId) async {
    try {
      final url = Uri.parse(
          "${ApiConstants.baseUrl}/api/dashboard/unread_counts.php?user_id=$userId");

      debugPrint("📡 Fetch unread counts: $url");

      final response =
          await http.get(url).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'notifications':
                int.tryParse(data['unread_notifications']?.toString() ?? '0') ??
                    0,
            'messages':
                int.tryParse(data['unread_messages']?.toString() ?? '0') ?? 0,
          };
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching unread counts: $e");
    }

    return {'notifications': 0, 'messages': 0};
  }

  /* ---------------- MARK ALL AS READ ---------------- */
  Future<bool> markAllAsRead(int userId) async {
    try {
      final url = Uri.parse("$_apiBase/update_all.php");

      debugPrint("📡 Mark all as read: $url");

      final response = await http
          .post(url, body: {
            'user_id': userId.toString(),
          })
          .timeout(ApiConstants.apiTimeout);

      debugPrint("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint("❌ Error marking all as read: $e");
    }

    return false;
  }
}
