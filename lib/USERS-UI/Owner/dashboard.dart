import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Services
import 'package:cargo/USERS-UI/Owner/dashboard/dashboard_service.dart';
import 'package:cargo/USERS-UI/Owner/dashboard/booking_service.dart';

// Models
import 'package:cargo/USERS-UI/Owner/dashboard/dashboard_stats.dart';
import 'package:cargo/USERS-UI/Owner/dashboard/booking_model.dart';

// Widgets
import 'package:cargo/USERS-UI/Owner/dashboard/dashboard_header.dart';
import 'package:cargo/USERS-UI/Owner/dashboard/stat_card_widget.dart';
import 'package:cargo/USERS-UI/Owner/dashboard/revenue_overview_widget.dart';
import 'package:cargo/USERS-UI/Owner/dashboard/quick_action_card.dart';
import 'package:cargo/USERS-UI/Owner/dashboard/recent_activity_widget.dart';
import 'package:cargo/USERS-UI/Owner/dashboard/upcoming_bookings_widget.dart';

// Pages
import 'package:cargo/USERS-UI/Owner/pending_requests_page.dart';
import 'package:cargo/USERS-UI/Owner/active_booking_page.dart';
import 'package:cargo/USERS-UI/Owner/cancelled_bookings_page.dart';
import 'package:cargo/USERS-UI/Owner/rejected_bookings_page.dart';
import 'package:cargo/USERS-UI/Owner/insurance/owner_insurance_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
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

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userName = prefs.getString("fullname") ?? "User";
      
      // Get owner ID
      ownerId = prefs.getString("user_id") ?? 
                prefs.getInt("user_id")?.toString() ?? 
                "0";
      debugPrint("PREF OWNER ID => $ownerId");
      // Fetch all data in parallel
      await Future.wait([
        _fetchDashboardStats().catchError((e) {
          debugPrint("⚠️ Dashboard stats fetch failed: $e");
        }),
        _fetchRecentBookings().catchError((e) {
          debugPrint("⚠️ Recent bookings fetch failed: $e");
        }),
        _fetchUpcomingBookings().catchError((e) {
          debugPrint("⚠️ Upcoming bookings fetch failed: $e");
        }),
      ]);
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }


  Future<void> _fetchDashboardStats() async {
    final fetchedStats = await _dashboardService.fetchDashboardStats(ownerId);
    debugPrint("👤 OWNER ID => $ownerId");

    if (mounted) setState(() => stats = fetchedStats);
  }

  Future<void> _fetchRecentBookings() async {

    final bookings =
        await _bookingService.fetchRecentBookings(ownerId, limit: 5);
    if (mounted) setState(() => recentBookings = bookings);
  }

  Future<void> _fetchUpcomingBookings() async {
    final bookings =
        await _bookingService.fetchUpcomingBookings(ownerId);
    if (mounted) setState(() => upcomingBookings = bookings);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

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
                  // Header (without notification icon)
                  DashboardHeader(userName: userName),
                  
                  if (isLoading)
                    _buildLoadingIndicator()
                  else ...[
                    const SizedBox(height: 24),
                    
                    // Quick Stats Grid (only Total Cars and Total Income)
                    _buildQuickStatsGrid(),
                    
                    const SizedBox(height: 24),
                    
                    // Revenue Overview
                    RevenueOverview(
                      totalIncome: stats.totalIncome,
                      monthlyIncome: stats.monthlyIncome,
                      weeklyIncome: stats.weeklyIncome,
                      todayIncome: stats.todayIncome,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions (Now includes all 4 actions)
                    _buildQuickActions(),
                    
                    const SizedBox(height: 24),
                    
                    // Upcoming Bookings
                    UpcomingBookingsWidget(
                      upcomingBookings: upcomingBookings,
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActiveBookingsPage(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Activity
                    RecentActivityWidget(recentBookings: recentBookings),
                    
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
        padding: EdgeInsets.all(48.0),
        child: CircularProgressIndicator(
  color: Theme.of(context).colorScheme.primary,
)

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
           iconBackgroundColor: Theme.of(context).colorScheme.primaryContainer,

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
          
          // Pending Requests
          QuickActionCard(
            title: "Pending Requests",
            subtitle: "Review and approve bookings",
            count: stats.pendingRequests,
            icon: Icons.pending_actions_outlined,
           backgroundColor: Theme.of(context).colorScheme.primary,


            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PendingRequestsPage(ownerId: ownerId),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          
          // Active Bookings
          QuickActionCard(
            title: "Active Bookings",
            subtitle: "Currently rented vehicles",
            count: stats.activeBookings,
            icon: Icons.event_available_outlined,
            backgroundColor: Theme.of(context).colorScheme.secondary,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActiveBookingsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          
          // Cancelled Bookings (NEW)
          QuickActionCard(
            title: "Cancelled Bookings",
            subtitle: "Bookings cancelled by renters",
            count: stats.cancelledBookings,
            icon: Icons.cancel_outlined,
            backgroundColor: Theme.of(context).colorScheme.tertiary,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CancelledBookingsPage(ownerId: ownerId),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          
          // Rejected Bookings (NEW)
          QuickActionCard(
            title: "Rejected Bookings",
            subtitle: "Bookings you have rejected",
            count: stats.rejectedBookings,
            icon: Icons.block_outlined,
            backgroundColor: Theme.of(context).colorScheme.error,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RejectedBookingsPage(ownerId: ownerId),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // NEW: Insurance Policies Card
          QuickActionCard(
            title: "Insurance Policies",
            subtitle: "View your vehicle insurance coverage",
            count: null, // Optional: Can add count if you fetch it
            icon: Icons.shield_outlined,
            backgroundColor: Colors.orange.shade600,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerInsuranceScreen(
                    ownerId: int.parse(ownerId),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}