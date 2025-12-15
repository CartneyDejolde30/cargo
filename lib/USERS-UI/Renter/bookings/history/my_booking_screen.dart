import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'booking_card_widget.dart';
import 'booking_empty_state_widget.dart';
import 'booking_tabs_widget.dart';
import 'package:flutter_application_1/USERS-UI/Renter/widgets/bottom_nav_bar.dart';

import 'package:flutter_application_1/USERS-UI/Renter/models/booking.dart';
import 'package:flutter_application_1/USERS-UI/services/booking_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  int _currentTabIndex = 0;
  int _selectedNavIndex = 1;

  late Future<List<Booking>> _bookingFuture;

  // 🔴 Replace with actual logged-in user id
  final String userId = "USER_ID_HERE";

  // =========================
  // LIFECYCLE
  // =========================
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    _bookingFuture = BookingService.getMyBookings(userId);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  // =========================
  // FILTERING LOGIC
  // =========================
  List<Booking> _filterBookings(List<Booking> all) {
  final now = DateTime.now();

  switch (_currentTabIndex) {
    case 0: // Active (approved + started)
      return all.where((b) {
        if (b.status != 'approved') return false;
        final pickup = DateTime.tryParse(b.pickupDate);
        return pickup != null && !pickup.isAfter(now);
      }).toList();

    case 1: // Pending
      return all.where((b) => b.status == 'pending').toList();

    case 2: // Upcoming (approved but future)
      return all.where((b) {
        if (b.status != 'approved') return false;
        final pickup = DateTime.tryParse(b.pickupDate);
        return pickup != null && pickup.isAfter(now);
      }).toList();

    case 3: // Past
      return all.where((b) =>
          b.status == 'completed' ||
          b.status == 'cancelled' ||
          b.status == 'rejected').toList();

    default:
      return [];
  }
}


  String _mapStatusForUI(String dbStatus) {
    switch (dbStatus) {
      case 'approved':
        return 'active';
      case 'pending':
        return 'pending';
      case 'completed':
      case 'cancelled':
      case 'rejected':
        return 'past';
      default:
        return 'pending';
    }
  }

  // =========================
  // BOTTOM NAV
  // =========================
  void _handleNavigation(int index) {
    if (_selectedNavIndex != index) {
      setState(() => _selectedNavIndex = index);
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildBookingBody()),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  // =========================
  // WIDGETS
  // =========================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'My Bookings',
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBookingBody() {
    return FutureBuilder<List<Booking>>(
      future: _bookingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return BookingEmptyStateWidget(
            onBrowseCars: () {
              Navigator.pushNamed(context, '/renters');
            },
          );
        }

        final bookings = _filterBookings(snapshot.data!);

        if (bookings.isEmpty) {
          return BookingEmptyStateWidget(
            onBrowseCars: () {
              Navigator.pushNamed(context, '/renters');
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BookingCardWidget(
                booking: bookings[index],
                status: _mapStatusForUI(bookings[index].status),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    return BookingTabsWidget(
      currentTabIndex: _currentTabIndex,
      onTabChanged: (index) {
        _tabController.animateTo(index);
      },
      // Badge counts can be wired later with real data
      badgeCounts: const [0, 0, 0, 0],
    );
  }
}
