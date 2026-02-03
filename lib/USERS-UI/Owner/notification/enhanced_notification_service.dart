import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../mycar/api_constants.dart';
import 'notification_model.dart';

/// Enhanced Notification Service with advanced features
class EnhancedNotificationService {
  static String get _baseUrl => ApiConstants.baseUrl;

  /// Fetch notifications with filtering
  Future<Map<String, dynamic>> fetchNotifications({
    required int userId,
    String? type,
    String? status, // 'read', 'unread', 'all'
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, String>{
        'user_id': userId.toString(),
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };

      final uri = Uri.parse('$_baseUrl/get_notification.php')
          .replace(queryParameters: params);

      final response = await http.get(uri).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['notifications'] is List) {
          final notifications = (data['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          return {
            'success': true,
            'notifications': notifications,
            'total_count': data['total_count'] ?? notifications.length,
            'unread_count': data['unread_count'] ?? 
                notifications.where((n) => n.isUnread).length,
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
    }

    return {
      'success': false,
      'notifications': <NotificationModel>[],
      'total_count': 0,
      'unread_count': 0,
    };
  }

  /// Get notifications grouped by type
  Future<Map<String, List<NotificationModel>>> fetchGroupedByType(int userId) async {
    final result = await fetchNotifications(userId: userId);
    
    if (result['success']) {
      final notifications = result['notifications'] as List<NotificationModel>;
      final grouped = <String, List<NotificationModel>>{};

      for (var notification in notifications) {
        final type = notification.type;
        if (!grouped.containsKey(type)) {
          grouped[type] = [];
        }
        grouped[type]!.add(notification);
      }

      return grouped;
    }

    return {};
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/delete_notification.php'),
        body: {
          'notification_id': notificationId.toString(),
          'user_id': userId.toString(),
        },
      ).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
    return false;
  }

  /// Archive notification
  Future<bool> archiveNotification(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/archive_notification.php'),
        body: {'id': notificationId.toString()},
      ).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('❌ Error archiving notification: $e');
    }
    return false;
  }

  /// Mark as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/mark_notification_read.php'),
        body: {'notification_id': notificationId},
      ).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
    }
    return false;
  }

  /// Mark all as read
  Future<bool> markAllAsRead(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/update_all.php'),
        body: {'user_id': userId.toString()},
      ).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
    return false;
  }

  /// Delete multiple notifications
  Future<Map<String, dynamic>> deleteMultiple(List<int> notificationIds, int userId) async {
    int successCount = 0;
    int failCount = 0;

    for (var id in notificationIds) {
      final success = await deleteNotification(id, userId);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    return {
      'success': failCount == 0,
      'deleted_count': successCount,
      'failed_count': failCount,
    };
  }

  /// Archive multiple notifications
  Future<Map<String, dynamic>> archiveMultiple(List<int> notificationIds) async {
    int successCount = 0;
    int failCount = 0;

    for (var id in notificationIds) {
      final success = await archiveNotification(id);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    return {
      'success': failCount == 0,
      'archived_count': successCount,
      'failed_count': failCount,
    };
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats(int userId) async {
    final result = await fetchNotifications(userId: userId);

    if (result['success']) {
      final notifications = result['notifications'] as List<NotificationModel>;
      
      final typeCount = <String, int>{};
      for (var notification in notifications) {
        typeCount[notification.type] = (typeCount[notification.type] ?? 0) + 1;
      }

      return {
        'total': notifications.length,
        'unread': notifications.where((n) => n.isUnread).length,
        'read': notifications.where((n) => !n.isUnread).length,
        'by_type': typeCount,
      };
    }

    return {
      'total': 0,
      'unread': 0,
      'read': 0,
      'by_type': <String, int>{},
    };
  }

  /// Search notifications
  Future<List<NotificationModel>> searchNotifications({
    required int userId,
    required String query,
  }) async {
    final result = await fetchNotifications(userId: userId);

    if (result['success']) {
      final notifications = result['notifications'] as List<NotificationModel>;
      final lowerQuery = query.toLowerCase();

      return notifications.where((notification) {
        return notification.title.toLowerCase().contains(lowerQuery) ||
               notification.message.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return [];
  }

  /// Get unread counts by category
  Future<Map<String, int>> getUnreadCountsByCategory(int userId) async {
    final result = await fetchNotifications(
      userId: userId,
      status: 'unread',
    );

    if (result['success']) {
      final notifications = result['notifications'] as List<NotificationModel>;
      final counts = <String, int>{};

      for (var notification in notifications) {
        counts[notification.type] = (counts[notification.type] ?? 0) + 1;
      }

      return counts;
    }

    return {};
  }
}
