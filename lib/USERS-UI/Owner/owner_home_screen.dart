import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
import '../Owner/notification/notification_service.dart';

// Pages
import 'dashboard.dart';
import 'mycar_page.dart';
import 'notification/enhanced_notification_page.dart'; // NEW: Enhanced Notifications
import 'message_page.dart';
import 'profile_page.dart';

// Widgets
import 'widgets/verify_popup.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final NotificationService _notificationService = NotificationService();

  int _selectedIndex = 0;
  int _ownerId = 0;
  bool _loading = true;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  
  // ✅ PERFORMANCE: Prevent multiple simultaneous API calls
  bool _isLoadingBadges = false;
  DateTime? _lastBadgeUpdate;
  
  // ✅ Timer for periodic updates
  Timer? _badgeUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // ✅ Start periodic badge updates
    _startPeriodicBadgeUpdate();
    
    // ✅ OPTIMIZATION: Defer verification popup to avoid blocking initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint("🔍 [OWNER SCREEN] About to check verification popup...");
        debugPrint("🔍 [OWNER SCREEN] Mounted: $mounted");
        if (mounted) {
          debugPrint("🔍 [OWNER SCREEN] Calling VerifyPopup.showIfNotVerified()");
          VerifyPopup.showIfNotVerified(context);
        } else {
          debugPrint("❌ [OWNER SCREEN] Widget not mounted, skipping popup");
        }
      });
    });
  }
  
  @override
  void dispose() {
    _stopPeriodicBadgeUpdate();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get user ID
      final userId = prefs.getString("user_id") ?? 
                     prefs.getInt("user_id")?.toString() ?? 
                     "0";
      
      debugPrint("🔑 SharedPreferences user_id: $userId");
      
      setState(() {
        _ownerId = int.tryParse(userId) ?? 0;
        _loading = false;
      });

      debugPrint("🔑 Parsed owner_id: $_ownerId");

      // ✅ OPTIMIZATION: Load badge counts in background (non-blocking)
      _loadBadgeCounts();
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() => _loading = false);
    }
  }

  // ✅ Start periodic badge count updates
  void _startPeriodicBadgeUpdate() {
    // Update immediately
    if (_ownerId > 0) {
      _loadBadgeCounts();
    }
    
    // Then update every 30 seconds (reduced frequency to prevent spam)
    _badgeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _ownerId > 0) {
        _loadBadgeCounts();
      }
    });
  }
  
  // ✅ Stop periodic updates
  void _stopPeriodicBadgeUpdate() {
    _badgeUpdateTimer?.cancel();
    _badgeUpdateTimer = null;
  }

  Future<void> _loadBadgeCounts() async {
    // ✅ PERFORMANCE: Prevent multiple simultaneous calls
    if (_isLoadingBadges) {
      debugPrint("⏭️ Badge count request skipped (already loading)");
      return;
    }
    
    // ✅ CACHE: Skip if updated within last 10 seconds
    if (_lastBadgeUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastBadgeUpdate!);
      if (timeSinceLastUpdate.inSeconds < 10) {
        debugPrint("⏭️ Badge count request skipped (cached, ${timeSinceLastUpdate.inSeconds}s ago)");
        return;
      }
    }
    
    _isLoadingBadges = true;
    
    try {
      final counts = await _notificationService.fetchUnreadCounts(_ownerId.toString());
      
      if (mounted) {
        setState(() {
          _unreadNotifications = counts['notifications'] ?? 0;
          _unreadMessages = counts['messages'] ?? 0;
          _lastBadgeUpdate = DateTime.now();
        });
        debugPrint("🔔 Badge counts updated: Notifications=$_unreadNotifications, Messages=$_unreadMessages");
      }
    } catch (e) {
      debugPrint("❌ Error loading badge counts: $e");
    } finally {
      _isLoadingBadges = false;
    }
  }

  void _onItemTapped(int index) {
    final previousIndex = _selectedIndex;
    
    setState(() {
      _selectedIndex = index;
    });

    // ✅ Only refresh badge counts when LEAVING notifications/messages tab
    // This updates the count after the user has potentially read some items
    if (previousIndex == 2 || previousIndex == 3) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _loadBadgeCounts();
      });
    }
  }

  // ✅ PERFORMANCE: Build pages lazily - only create when first needed
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();
      case 1:
        return MyCarPage(ownerId: _ownerId);
      case 2:
        return EnhancedNotificationPage(userId: _ownerId);
      case 3:
        return const MessagePage();
      case 4:
        return const ProfileScreen();
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).iconTheme.color,



            strokeWidth: 3,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ✅ PERFORMANCE: Only render the current page instead of all pages
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.directions_car_rounded,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.notifications_rounded,
                index: 2,
                badgeCount: _unreadNotifications,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                index: 3,
                badgeCount: _unreadMessages,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    int? badgeCount,
  }) {
    final bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey.shade400,
              size: 24,
            ),
          ),
          // Badge
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: 8,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A1A1A),
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
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