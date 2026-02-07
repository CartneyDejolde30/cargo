import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String createdAt;
  final String readStatus; // "read" or "unread"

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.readStatus,
    
  });
  NotificationModel copyWith({
  String? readStatus,
}) {
  return NotificationModel(
    id: id,
    title: title,
    message: message,
    type: type,
    createdAt: createdAt,
    readStatus: readStatus ?? this.readStatus,
  );
}


  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      createdAt: json['created_at']?.toString() ?? '',
      readStatus: json['read_status']?.toString() ?? 'unread',
    );
  }

  bool get isUnread => readStatus.toLowerCase() == 'unread';

  // ===============================
  // ICON & COLOR HELPERS
  // ===============================

  IconData get icon {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('booking') || lowerTitle.contains('request')) {
      return Icons.bookmark_outline;
    } else if (lowerTitle.contains('payment') || lowerTitle.contains('paid')) {
      return Icons.payment_outlined;
    } else if (lowerTitle.contains('confirm')) {
      return Icons.check_circle_outline;
    } else if (lowerTitle.contains('rental') || lowerTitle.contains('end')) {
      return Icons.event_available_outlined;
    } else if (lowerTitle.contains('cancel')) {
      return Icons.cancel_outlined;
    } else {
      return Icons.notifications_outlined;
    }
  }

  Color get color {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('booking') || lowerTitle.contains('request')) {
      return Colors.blue;
    } else if (lowerTitle.contains('payment')) {
      return Colors.green;
    } else if (lowerTitle.contains('confirm')) {
      return Colors.teal;
    } else if (lowerTitle.contains('cancel')) {
      return Colors.red;
    } else if (lowerTitle.contains('rental')) {
      return Colors.orange;
    } else {
      return Colors.purple;
    }
  }

  // ===============================
  // DATE FORMATTERS
  // ===============================

  // Format time (HH:mm)
  String get formattedTime {
    try {
      final date = DateTime.parse(createdAt);
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  // Format date (January 22, 2026)
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return "${_monthName(date.month)} ${date.day}, ${date.year}";
    } catch (e) {
      return '';
    }
  }

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }
}
