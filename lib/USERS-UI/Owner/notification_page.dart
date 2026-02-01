import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Owner/notification/notification_service.dart';
import '../Owner/notification/notification_model.dart';
import '../Owner/notification/notification_helper.dart';

class NotificationPage extends StatefulWidget {
  final int userId;
  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> 
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<NotificationModel> notifications = [];
  Map<String, List<NotificationModel>> groupedNotifications = {};
  
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int lastCount = 0;
  
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
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

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadNotifications(silent: true),
    );
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      final fetchedNotifications = await _notificationService.fetchNotifications(widget.userId);

      if (fetchedNotifications.length > lastCount && silent && lastCount > 0) {
        await _playAlertSound();
        _vibrate();
      }

      lastCount = fetchedNotifications.length;

      setState(() {
        notifications = fetchedNotifications;
        groupedNotifications = NotificationHelper.groupByDate(fetchedNotifications);
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading notifications: $e");
      
      if (!silent) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = NotificationHelper.getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource("notification_sound.mp3"));
    } catch (e) {
      debugPrint("❌ Error playing sound: $e");
    }
  }

  void _vibrate() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 80);
      }
    } catch (e) {
      debugPrint("❌ Error vibrating: $e");
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Delete Notification",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete this notification? This action cannot be undone.",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Delete", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _notificationService.deleteNotification(notification.id,
  widget.userId,);

      if (success) {
        setState(() {
          notifications.removeWhere((n) => n.id == notification.id);
          groupedNotifications = NotificationHelper.groupByDate(notifications);
        });

        if (mounted) {
          _showSnackBar(
            icon: Icons.delete_sweep_rounded,
            message: 'Notification deleted',
            backgroundColor: Colors.red.shade600,
          );
        }
      } else {
        if (mounted) {
          _showSnackBar(
            icon: Icons.error_outline,
            message: 'Failed to delete notification',
            backgroundColor: Colors.red.shade600,
          );
        }
      }
    }
  }

  void _openNotificationDetail(NotificationModel notification) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notification: notification,
          onDelete: () {
            Navigator.pop(context);
            _deleteNotification(notification);
          },
          onArchive: () {
            Navigator.pop(context);
            _archiveNotification(notification.id);
          },
        ),
      ),
    );
  }

  Future<void> _archiveNotification(int notificationId) async {
    final success = await _notificationService.archiveNotification(notificationId);

    if (success) {
      setState(() {
        notifications.removeWhere((n) => n.id == notificationId);
        groupedNotifications = NotificationHelper.groupByDate(notifications);
      });

      if (mounted) {
        _showSnackBar(
          icon: Icons.archive_outlined,
          message: 'Notification archived',
          backgroundColor: Colors.orange.shade700,
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead(widget.userId);
    if (success) {
      _loadNotifications(silent: true);
      if (mounted) {
        _showSnackBar(
          icon: Icons.check_circle_outline,
          message: 'All notifications marked as read',
          backgroundColor: Colors.green.shade600,
        );
      }
    }
  }

  void _showSnackBar({required IconData icon, required String message, required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getIconByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.event_available_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'info':
        return Icons.info_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Colors.blue.shade600;
      case 'payment':
        return Colors.green.shade600;
      case 'alert':
        return Colors.orange.shade600;
      case 'success':
        return Colors.teal.shade600;
      case 'message':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n.isUnread).length;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(unreadCount),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(int unreadCount) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              color: Theme.of(context).iconTheme.color,



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
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(
                "Mark all read",
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).iconTheme.color,


                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.black),
            const SizedBox(height: 16),
            Text(
              "Loading notifications...",
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    if (hasError) return _buildErrorState();
    if (groupedNotifications.isEmpty) return _buildEmptyState();
    return _buildNotificationList();
  }

  Widget _buildErrorState() {
    return Center(
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
              child: Icon(Icons.cloud_off_outlined, size: 64, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              "Connection Error",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Try Again', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                 backgroundColor: Theme.of(context).iconTheme.color,




                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            "No notifications yet",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you when something arrives",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: Theme.of(context).iconTheme.color,



        child: ListView(
          padding: const EdgeInsets.all(20),
          children: groupedNotifications.entries.map((section) {
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
                ...section.value.map((n) => _buildNotificationItem(n)),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel n) {
    final color = _getColorByType(n.type);
    final icon = _getIconByType(n.type);
    final isUnread = n.isUnread;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openNotificationDetail(n),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: GoogleFonts.poppins(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.message,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            n.formattedTime,
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'delete') _deleteNotification(n);
                    if (v == 'archive') _archiveNotification(n.id);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 20, color: Colors.orange.shade600),
                          const SizedBox(width: 12),
                          Text('Archive', style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade600),
                          const SizedBox(width: 12),
                          Text('Delete', style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDelete;
  final VoidCallback onArchive;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    required this.onDelete,
    required this.onArchive,
  });

  IconData _getIconByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.event_available_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'info':
        return Icons.info_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Colors.blue.shade600;
      case 'payment':
        return Colors.green.shade600;
      case 'alert':
        return Colors.orange.shade600;
      case 'success':
        return Colors.teal.shade600;
      case 'message':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorByType(notification.type);
    final icon = _getIconByType(notification.type);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Notification Details",
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,



            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'delete') onDelete();
              if (v == 'archive') onArchive();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 20, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Text('Archive', style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Text('Delete', style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
            ],
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 48),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                notification.type.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              notification.title,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  notification.formattedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  notification.formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                notification.message,
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