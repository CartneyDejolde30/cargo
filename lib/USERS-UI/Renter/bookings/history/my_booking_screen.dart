import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_card_widget.dart';
import 'booking_empty_state_widget.dart';
import 'temp_booking_data.dart';
import 'booking_tabs_widget.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getBookingsForTab() {
    switch (_currentTabIndex) {
      case 0:
        return TempBookingData.activeBookings;
      case 1:
        return TempBookingData.pendingBookings;
      case 2:
        return TempBookingData.upcomingBookings;
      case 3:
        return TempBookingData.pastBookings;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _getBookingsForTab();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          _buildTabBar(),
          SizedBox(height: 24),
          Expanded(
            child: bookings.isEmpty
                ? BookingEmptyStateWidget(
                    onBrowseCars: () {
                      // Navigate to car browse screen
                      print('Browse cars tapped');
                    },
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: BookingCardWidget(
                          booking: bookings[index],
                          status: _getStatusForTab(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getStatusForTab() {
    switch (_currentTabIndex) {
      case 0:
        return 'active';
      case 1:
        return 'pending';
      case 2:
        return 'upcoming';
      case 3:
        return 'past';
      default:
        return 'active';
    }
  }

 Widget _buildTabBar() {
  return BookingTabsWidget(
    currentTabIndex: _currentTabIndex,
    onTabChanged: (index) {
      _tabController.animateTo(index);
    },
    // Optional: Add badge counts
    badgeCounts: [
      TempBookingData.activeBookings.length,
      TempBookingData.pendingBookings.length,
      TempBookingData.upcomingBookings.length,
      TempBookingData.pastBookings.length,
    ],
  );
}

  Widget _buildTab(String label, int index) {
    bool isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}