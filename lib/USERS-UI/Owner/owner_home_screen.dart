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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // ✅ OPTIMIZATION: Defer verification popup to avoid blocking initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          VerifyPopup.showIfNotVerified(context);
        }
      });
    });
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

  Future<void> _loadBadgeCounts() async {
    try {
      final counts = await _notificationService.fetchUnreadCounts(_ownerId.toString());
      
      setState(() {
        _unreadNotifications = counts['notifications'] ?? 0;
        _unreadMessages = counts['messages'] ?? 0;
      });
    } catch (e) {
      debugPrint("Error loading badge counts: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Refresh badge counts when navigating to notifications or messages
    if (index == 2 || index == 3) {
      _loadBadgeCounts();
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

    final List<Widget> pages = [
      const DashboardPage(),
      MyCarPage(ownerId: _ownerId),
      EnhancedNotificationPage(userId: _ownerId), // NEW: Using Enhanced Notifications
      const MessagePage(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
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