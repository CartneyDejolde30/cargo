import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Services
import './dashboard/dashboard_service.dart';
import '../Owner/dashboard/booking_service.dart';

// Models
import './dashboard/dashboard_stats.dart';
import './dashboard/booking_model.dart';

// Widgets
import './dashboard/dashboard_header.dart';
import './dashboard/stat_card_widget.dart';
// import './dashboard/revenue_overview_widget.dart'; // REMOVED - Replaced by revenue_breakdown_widget
import './dashboard/revenue_breakdown_widget.dart'; // Revenue breakdown with detailed view
import './dashboard/quick_action_card.dart';
import './dashboard/recent_activity_widget.dart';
import './dashboard/upcoming_bookings_widget.dart';

// Analytics Dashboard - NEW
import './analytics/analytics_dashboard_screen.dart';

// Pages
import 'pending_requests_page.dart';
import 'active_booking_page.dart';
import 'cancelled_bookings_page.dart';
import 'rejected_bookings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final DashboardService _dashboardService = DashboardService();
  final BookingService _bookingService = BookingService();

  bool isDarkMode = false;

  String userName = "User";
  String ownerId = "0";

  DashboardStats stats = DashboardStats.empty();
  List<Booking> recentBookings = [];
  List<Booking> upcomingBookings = [];

  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  // =====================
  // LOAD DATA + THEME
  // =====================
  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      userName = prefs.getString("fullname") ?? "User";
      isDarkMode = prefs.getBool("isDarkMode") ?? false;

      ownerId = prefs.getString("user_id") ??
          prefs.getInt("user_id")?.toString() ??
          "0";

      await Future.wait([
        _fetchDashboardStats(),
        _fetchRecentBookings(),
        _fetchUpcomingBookings(),
      ]);
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    }

    setState(() => isLoading = false);
  }

  // =====================
  // THEME TOGGLE
  // =====================
  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
    });
    await prefs.setBool("isDarkMode", isDarkMode);
  }

  Future<void> _fetchDashboardStats() async {
    final fetchedStats =
        await _dashboardService.fetchDashboardStats(ownerId);
    debugPrint("👤 OWNER ID => $ownerId");

    setState(() => stats = fetchedStats);
  }

  Future<void> _fetchRecentBookings() async {
    final bookings =
        await _bookingService.fetchRecentBookings(ownerId, limit: 5);
    setState(() => recentBookings = bookings);
  }

  Future<void> _fetchUpcomingBookings() async {
    final bookings =
        await _bookingService.fetchUpcomingBookings(ownerId);
    setState(() => upcomingBookings = bookings);
  }

  String _formatCurrency(double amount) {
    final formatter =
        NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Theme.of(context).colorScheme.primary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER WITH TOGGLE
                  DashboardHeader(
                    userName: userName,
                    isDarkMode: isDarkMode,
                    onToggleTheme: _toggleTheme,
                  ),

                  if (isLoading)
                    _buildLoadingIndicator()
                  else ...[
                    const SizedBox(height: 24),
                    _buildQuickStatsGrid(),
                    
                    // Revenue Breakdown Widget - Replaces old RevenueOverview
                    if (stats.revenueBreakdown != null) ...[
                      const SizedBox(height: 24),
                      ExpandableRevenueBreakdown(
                        revenueBreakdown: stats.revenueBreakdown,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    UpcomingBookingsWidget(
                      upcomingBookings: upcomingBookings,
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ActiveBookingsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    RecentActivityWidget(
                      recentBookings: recentBookings,
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.52,
        children: [
          StatCard(
            title: "Total Cars",
            value: "${stats.totalCars}",
            icon: Icons.directions_car_outlined,
            subtitle: "${stats.approvedCars} active",
          ),
          StatCard(
            title: "Total Income",
            value: _formatCurrency(stats.totalIncome),
            icon: Icons.account_balance_wallet_outlined,
            iconBackgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // NEW: Analytics Dashboard Card
          _buildAnalyticsDashboardCard(),
          const SizedBox(height: 14),

          QuickActionCard(
            title: "Pending Requests",
            subtitle: "Review and approve bookings",
            count: stats.pendingRequests,
            icon: Icons.pending_actions_outlined,
            backgroundColor:
                Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PendingRequestsPage(ownerId: ownerId),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          QuickActionCard(
            title: "Active Bookings",
            subtitle: "Currently rented vehicles",
            count: stats.activeBookings,
            icon: Icons.event_available_outlined,
            backgroundColor:
                Theme.of(context).colorScheme.secondary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ActiveBookingsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          QuickActionCard(
            title: "Cancelled Bookings",
            subtitle: "Bookings cancelled by renters",
            count: stats.cancelledBookings,
            icon: Icons.cancel_outlined,
            backgroundColor:
                Theme.of(context).colorScheme.tertiary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CancelledBookingsPage(
                          ownerId: ownerId),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          QuickActionCard(
            title: "Rejected Bookings",
            subtitle: "Bookings you have rejected",
            count: stats.rejectedBookings,
            icon: Icons.block_outlined,
            backgroundColor:
                Theme.of(context).colorScheme.error,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RejectedBookingsPage(
                          ownerId: ownerId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // NEW: Analytics Dashboard Card
  Widget _buildAnalyticsDashboardCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyticsDashboardScreen(
              ownerId: int.parse(ownerId),
              ownerName: userName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.blue.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View detailed business insights',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
