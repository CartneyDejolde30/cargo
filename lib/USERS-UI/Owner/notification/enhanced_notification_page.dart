import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'enhanced_notification_service.dart';
import 'notification_model.dart';
import 'notification_helper.dart';

class EnhancedNotificationPage extends StatefulWidget {
  final int userId;
  
  const EnhancedNotificationPage({
    super.key,
    required this.userId,
  });

  @override
  State<EnhancedNotificationPage> createState() => _EnhancedNotificationPageState();
}

class _EnhancedNotificationPageState extends State<EnhancedNotificationPage> 
    with SingleTickerProviderStateMixin {
  final EnhancedNotificationService _service = EnhancedNotificationService();
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  Map<String, int> _unreadCounts = {};
  
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedIds = {};
  String _selectedFilter = 'all';
  String _searchQuery = '';
  
  Timer? _refreshTimer;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['all', 'unread', 'booking', 'payment', 'alert'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _loadNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadNotifications(silent: true),
    );
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final result = await _service.fetchNotifications(
        userId: widget.userId,
        status: _selectedFilter == 'unread' ? 'unread' : null,
        type: (_selectedFilter != 'all' && _selectedFilter != 'unread') 
            ? _selectedFilter 
            : null,
      );

      if (result['success']) {
        final counts = await _service.getUnreadCountsByCategory(widget.userId);
        
        setState(() {
          _notifications = result['notifications'];
          _unreadCounts = counts;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (!silent) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = _notifications;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((n) => 
        n.title.toLowerCase().contains(query) ||
        n.message.toLowerCase().contains(query)
      ).toList();
    }

    _filteredNotifications = filtered;
  }

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

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Delete ${_selectedIds.length} notification(s)?',
      'This action cannot be undone.',
    );

    if (confirmed) {
      final result = await _service.deleteMultiple(
        _selectedIds.toList(),
        widget.userId,
      );

      if (result['success']) {
        _showSnackBar(
          '${result['deleted_count']} notification(s) deleted',
          Colors.green,
        );
        setState(() {
          _notifications.removeWhere((n) => _selectedIds.contains(n.id));
          _selectedIds.clear();
          _isSelectionMode = false;
          _applyFilters();
        });
      }
    }
  }

  Future<void> _archiveSelected() async {
    if (_selectedIds.isEmpty) return;

    final result = await _service.archiveMultiple(_selectedIds.toList());

    if (result['success']) {
      _showSnackBar(
        '${result['archived_count']} notification(s) archived',
        Colors.orange,
      );
      setState(() {
        _notifications.removeWhere((n) => _selectedIds.contains(n.id));
        _selectedIds.clear();
        _isSelectionMode = false;
        _applyFilters();
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
      title: _isSelectionMode
          ? Text(
              '${_selectedIds.length} selected',
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
            )
          : Text(
              'Notifications',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: [
        if (!_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: _showSearchBar,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _service.markAllAsRead(widget.userId);
                _loadNotifications();
              } else if (value == 'select_mode') {
                setState(() => _isSelectionMode = true);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    const Icon(Icons.done_all, size: 20),
                    const SizedBox(width: 12),
                    Text('Mark all as read', style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'select_mode',
                child: Row(
                  children: [
                    const Icon(Icons.checklist, size: 20),
                    const SizedBox(width: 12),
                    Text('Select mode', style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all, color: Colors.black),
            onPressed: () => setState(() {
              if (_selectedIds.length == _filteredNotifications.length) {
                _selectedIds.clear();
              } else {
                _selectedIds = _filteredNotifications.map((n) => n.id).toSet();
              }
            }),
          ),
        ],
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildFilterTabs(),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.black,
        onTap: (index) {
          setState(() {
            _selectedFilter = _filters[index];
            _loadNotifications();
          });
        },
        tabs: _filters.map((filter) {
          final count = filter == 'all'
              ? _notifications.length
              : filter == 'unread'
                  ? _notifications.where((n) => n.isUnread).length
                  : _unreadCounts[filter] ?? 0;

          return Tab(
            child: Row(
              children: [
                Text(
                  filter.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final grouped = NotificationHelper.groupByDate(_filteredNotifications);

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final entry = grouped.entries.elementAt(index);
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
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ...entry.value.map((notification) => 
                _buildNotificationCard(notification)
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isSelected = _selectedIds.contains(notification.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(notification.id),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(notification.icon, color: notification.color),
              ),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(
            fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: GoogleFonts.poppins(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification.formattedTime,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: notification.isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(notification.id);
          } else {
            // Navigate to detail
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _toggleSelection(notification.id);
          });
        },
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchBar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Notifications', style: GoogleFonts.poppins()),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
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
            child: Text('Done', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
