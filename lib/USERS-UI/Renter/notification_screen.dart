import 'dart:async';
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

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 2;

  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedIds = {};
  
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  Map<String, List<Map<String, dynamic>>> _grouped = {};

  final AudioPlayer player = AudioPlayer();
  int? _loadedUserId;
  
  Timer? _refreshTimer;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'all';
  String _searchQuery = '';
  
  final List<String> _filters = ['all', 'unread', 'booking', 'payment', 'alert'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _loadUserId();
    _listenToFCM();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    player.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadInitialNotifications(silent: true),
    );
  }

  // ============== LOAD USER_ID ==============

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString("user_id");

    if (savedId != null) {
      _loadedUserId = int.tryParse(savedId);
    }

    _loadedUserId ??= widget.userId;
    print("🔥 Loaded user_id: $_loadedUserId");

    _loadInitialNotifications();
  }

  // ============== LOAD NOTIFICATIONS ==============

  Future<void> _loadInitialNotifications({bool silent = false}) async {
    if (_loadedUserId == null) {
      print("❌ user_id is NULL");
      setState(() => _isLoading = false);
      return;
    }

    if (!silent) setState(() => _isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(
            "http://10.77.127.2/carGOAdmin/get_notification_renter.php?user_id=$_loadedUserId"),
      ).timeout(const Duration(seconds: 10));

      print("📩 RAW RESPONSE: ${res.body}");

      final decoded = jsonDecode(res.body);

      if (decoded is! Map || decoded["status"] != "success") {
        setState(() {
          _notifications = [];
          _grouped.clear();
          _isLoading = false;
        });
        return;
      }

      final rawList = decoded["notifications"];
      final List<Map<String, dynamic>> safeList =
          (rawList is List) ? List<Map<String, dynamic>>.from(rawList) : [];

      setState(() {
        _notifications = safeList;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print("❌ ERROR: $e");
      setState(() {
        _notifications = [];
        _grouped.clear();
        _isLoading = false;
      });
    }
  }

  // ============== APPLY FILTERS ==============

  void _applyFilters() {
    var filtered = _notifications;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((n) =>
          (n["title"] ?? "").toString().toLowerCase().contains(query) ||
          (n["message"] ?? "").toString().toLowerCase().contains(query))
          .toList();
    }

    _filteredNotifications = filtered;
    _groupByDate();
  }

  // ============== GROUP BY DATE ==============

  void _groupByDate() {
    _grouped.clear();

    for (var n in _filteredNotifications) {
      String date = n["date"] ?? "Unknown";

      if (!_grouped.containsKey(date)) {
        _grouped[date] = [];
      }

      _grouped[date]!.add(n);
    }
  }

  // ============== REALTIME FCM LISTENER ==============

  void _listenToFCM() {
    FirebaseMessaging.onMessage.listen((message) {
      _playSound();
      _vibrate();

      Map<String, dynamic> newNotif = {
        "id": int.tryParse(message.data["id"] ?? "0") ?? 0,
        "title": message.notification?.title ?? "Notification",
        "message": message.notification?.body ?? "",
        "date": message.data["date"] ?? "Today",
        "time": message.data["time"] ?? "",
        "type": message.data["type"] ?? "info",
        "isRead": false
      };

      setState(() {
        _notifications.insert(0, newNotif);
        _applyFilters();
      });
    });
  }

  // ============== SOUND + VIBRATE ==============

  Future<void> _playSound() async {
    try {
      await player.play(AssetSource("notification_sound.mp3"));
    } catch (e) {
      print("Sound play error: $e");
    }
  }

  void _vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 80);
    }
  }

  // ============== SELECTION MODE ==============

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  // ============== MARK AS READ ==============

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    setState(() {
      notification["isRead"] = true;
    });
  }

  // ============== DELETE NOTIFICATION ==============

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final confirmed = await _showConfirmDialog(
      'Delete notification?',
      'This action cannot be undone.',
    );

    if (confirmed) {
      setState(() {
        _notifications.remove(notification);
        _applyFilters();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============== DELETE MULTIPLE ==============

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Delete ${_selectedIds.length} notification(s)?',
      'This action cannot be undone.',
    );

    if (confirmed) {
      setState(() {
        _notifications.removeWhere((n) => _selectedIds.contains(n["id"] as int));
        _selectedIds.clear();
        _isSelectionMode = false;
        _applyFilters();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} notification(s) deleted', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============== ARCHIVE MULTIPLE ==============

  Future<void> _archiveSelected() async {
    if (_selectedIds.isEmpty) return;

    setState(() {
      _notifications.removeWhere((n) => _selectedIds.contains(n["id"] as int));
      _selectedIds.clear();
      _isSelectionMode = false;
      _applyFilters();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedIds.length} notification(s) archived', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============== OPEN DETAIL ==============

  void _openNotificationDetail(Map<String, dynamic> notification) async {
    if (_isSelectionMode) {
      _toggleSelection(notification["id"] ?? 0);
      return;
    }

    await _markAsRead(notification);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetailScreen(
            notification: notification,
            onDelete: () {
              Navigator.pop(context);
              _deleteNotification(notification);
            },
          ),
        ),
      );
    }
  }

  // ============== SHOW CONFIRM DIALOG ==============

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: isDark ? colors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: isDark ? colors.onSurface : Colors.black),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(color: isDark ? colors.onSurfaceVariant : Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: isDark ? colors.onSurfaceVariant : Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // ============== SHOW SEARCH DIALOG ==============

  void _showSearchBar() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: isDark ? colors.surface : Colors.white,
          title: Text('Search Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter search term...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? colors.surfaceContainerHighest : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _applyFilters();
                });
                Navigator.pop(context);
              },
              child: Text('Clear', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Done', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ============== GET ICON BY TYPE ==============

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
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ============== BUILD WIDGET ==============

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final unreadCount = _notifications.where((n) => !(n["isRead"] ?? false)).length;

    return Scaffold(
      backgroundColor: isDark ? colors.background : Colors.grey[50],
      appBar: _buildAppBar(isDark, colors, unreadCount),
      body: _isLoading ? _buildLoading(colors) : (_grouped.isEmpty ? _buildEmptyState(isDark, colors) : _buildNotificationsList()),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBar() : BottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, ColorScheme colors, int unreadCount) {
    return AppBar(
      backgroundColor: isDark ? colors.surface : Colors.white,
      elevation: 0,
      leading: _isSelectionMode
          ? IconButton(
              icon: Icon(Icons.close, color: isDark ? colors.onSurface : Colors.black),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            )
          : IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? colors.onSurface : Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
      title: _isSelectionMode
          ? Text(
              '${_selectedIds.length} selected',
              style: GoogleFonts.poppins(color: isDark ? colors.onSurface : Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
            )
          : Text(
              'Notifications',
              style: GoogleFonts.poppins(
                color: isDark ? colors.onSurface : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
      actions: [
        if (!_isSelectionMode) ...[
          IconButton(
            icon: Icon(Icons.search, color: isDark ? colors.onSurface : Colors.black),
            onPressed: _showSearchBar,
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n["isRead"] = true;
                  }
                });
              },
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? colors.onSurface : Colors.black),
              ),
            ),
        ],
        if (_isSelectionMode) ...[
          IconButton(
            icon: Icon(Icons.select_all, color: isDark ? colors.onSurface : Colors.black),
            onPressed: () => setState(() {
              if (_selectedIds.length == _filteredNotifications.length) {
                _selectedIds.clear();
              } else {
                _selectedIds = _filteredNotifications.map((n) => (n["id"] as int? ?? 0)).toSet();
              }
            }),
          ),
        ],
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildFilterTabs(isDark, colors),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark, ColorScheme colors) {
    return Container(
      color: isDark ? colors.surface : Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: isDark ? colors.onSurface : Colors.black,
        unselectedLabelColor: isDark ? colors.onSurfaceVariant : Colors.grey,
        indicatorColor: isDark ? colors.onSurface : Colors.black,
        onTap: (index) {
          setState(() {
            _selectedFilter = _filters[index];
          });
        },
        tabs: _filters.map((filter) {
          final count = filter == 'all'
              ? _notifications.length
              : filter == 'unread'
                  ? _notifications.where((n) => !(n["isRead"] ?? false)).length
                  : _notifications.where((n) => (n["type"] ?? "").toLowerCase() == filter).length;

          return Tab(
            child: Row(
              children: [
                Text(
                  filter.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('$count', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoading(ColorScheme colors) {
    return Center(
      child: CircularProgressIndicator(color: colors.primary),
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: colors.outline),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.poppins(fontSize: 16, color: isDark ? colors.onSurfaceVariant : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadInitialNotifications,
      color: colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grouped.length,
        itemBuilder: (context, index) {
          final entry = _grouped.entries.elementAt(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colors.onSurfaceVariant : Colors.grey[700],
                  ),
                ),
              ),
              ...entry.value.map((notification) => _buildNotificationCard(notification)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedIds.contains(notification["id"] as int);
    final isRead = notification["isRead"] ?? false;
    final type = notification["type"] ?? "info";
    final icon = _getIconByType(type);
    final color = _getColorByType(type);

    return GestureDetector(
      onTap: () => _openNotificationDetail(notification),
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _toggleSelection(notification["id"] ?? 0);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? (isSelected ? colors.primaryContainer : colors.surface) : (isSelected ? Colors.blue.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(12),
         
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  activeColor: colors.primary,
                  checkColor: colors.onPrimary,
                  onChanged: (_) => _toggleSelection(notification["id"] ?? 0),
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
          title: Text(
            notification["title"] ?? "Notification",
            style: GoogleFonts.poppins(
              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
              fontSize: 14,
              color: isDark ? colors.onSurface : Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification["message"] ?? "",
                style: GoogleFonts.poppins(fontSize: 12, color: isDark ? colors.onSurfaceVariant : Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification["time"] ?? "",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDark ? colors.onSurfaceVariant : Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _archiveSelected,
              icon: const Icon(Icons.archive),
              label: const Text('Archive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    setState(() => _selectedNavIndex = index);
  }
}

// ============== NOTIFICATION DETAIL SCREEN ==============

class NotificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDelete;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    required this.onDelete,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late Map<String, dynamic> notification;

  @override
  void initState() {
    super.initState();
    notification = widget.notification;
  }

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
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final type = notification["type"] ?? "info";
    final icon = _getIconByType(type);
    final color = _getColorByType(type);

    return Scaffold(
      backgroundColor: isDark ? colors.background : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? colors.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? colors.onSurface : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Details',
          style: GoogleFonts.poppins(
            color: isDark ? colors.onSurface : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? colors.onSurface : Colors.black),
            onSelected: (value) {
              if (value == 'delete') {
                widget.onDelete();
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification["title"] ?? "Notification",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? colors.onSurface : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${notification['date']} • ${notification['time']}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDark ? colors.onSurfaceVariant : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Message section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
               
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? colors.onSurfaceVariant : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification["message"] ?? "No message",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: isDark ? colors.onSurface : Colors.black,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? colors.onSurfaceVariant : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Type', (notification["type"] as String?)?.toUpperCase() ?? "INFO", isDark, colors),
                  const SizedBox(height: 12),
                  _buildDetailRow('Status', (notification["isRead"] ?? false) ? 'Read' : 'Unread', isDark, colors),
                  const SizedBox(height: 12),
                  _buildDetailRow('Date & Time', "${notification['date']} • ${notification['time']}", isDark, colors),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onDelete();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? colors.onSurfaceVariant : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceContainerHighest : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? colors.onSurface : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}