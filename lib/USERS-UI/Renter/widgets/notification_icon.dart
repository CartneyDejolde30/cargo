import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../notification_screen.dart';
import 'package:flutter_application_1/config/api_config.dart';

class NotificationIcon extends StatefulWidget {
  final Color? iconColor;
  final double size;
  
  const NotificationIcon({
    super.key,
    this.iconColor,
    this.size = 24,
  });

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        '${GlobalApiConfig.baseUrl}/get_notification_renter.php?user_id=$userId'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          final notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          final unread = notifications.where((n) => n['isRead'] != true).length;
          
          setState(() {
            _unreadCount = unread;
            _isLoading = false;
          });
        } else {
          setState(() {
            _unreadCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('user_id');
    
    if (userIdStr == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view notifications')),
        );
      }
      return;
    }

    final userId = int.tryParse(userIdStr);
    if (userId == null) return;

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationScreen(userId: userId),
        ),
      );
      
      // Refresh count after returning from notification screen
      _fetchUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: widget.size,
              color: widget.iconColor ?? Colors.black,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
