import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<List<Booking>>? _bookingFuture;
  
  String? userId;
  bool _isLoading = true;

  // Badge counts for each tab
  int _activeCount = 0;
  int _pendingCount = 0;
  int _pastCount = 0;

  // Tab labels
  final List<String> _tabLabels = ['Active', 'Pending', 'Past'];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    _loadUserIdAndFetchBookings();
  }

  Future<void> _loadUserIdAndFetchBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loadedUserId = prefs.getString('user_id');

      if (loadedUserId == null || loadedUserId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showLoginRequiredDialog();
        }
        return;
      }

      if (mounted) {
        setState(() {
          userId = loadedUserId;
          _bookingFuture = BookingService.getMyBookings(userId!);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user ID: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // OPTIMIZED: Calculate badge counts from existing bookings data
  void _updateBadgeCountsFromBookings(List<Booking> bookings) {
    final now = DateTime.now();
    
    _activeCount = bookings.where((b) {
      if (b.status != 'approved') return false;
      final pickup = _parseDate(b.pickupDate);
      final returnDate = _parseDate(b.returnDate);
      return pickup != null && returnDate != null && 
             !pickup.isAfter(now) && !returnDate.isBefore(now);
    }).length;
    
    _pendingCount = bookings.where((b) => b.status == 'pending').length;
    
    _pastCount = bookings.where((b) =>
      b.status == 'completed' ||
      b.status == 'cancelled' ||
      b.status == 'rejected'
    ).length;
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Login Required'),
        content: Text('Please log in to view your bookings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
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

  List<Booking> _filterBookings(List<Booking> all) {
    final now = DateTime.now();

    switch (_currentTabIndex) {
      case 0: // Active
        return all.where((b) {
          if (b.status != 'approved') return false;
          final pickup = _parseDate(b.pickupDate);
          final returnDate = _parseDate(b.returnDate);
          return pickup != null && returnDate != null && 
                 !pickup.isAfter(now) && !returnDate.isBefore(now);
        }).toList();

      case 1: // Pending
        return all.where((b) => b.status == 'pending').toList();

      case 2: // Past
        return all.where((b) =>
          b.status == 'completed' ||
          b.status == 'cancelled' ||
          b.status == 'rejected'
        ).toList();

      default:
        return [];
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      } else {
        final parts = dateStr.split(' ');
        if (parts.length >= 3) {
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
            'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
            'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
          };
          final month = monthMap[parts[0]];
          final day = int.tryParse(parts[1].replaceAll(',', ''));
          final year = int.tryParse(parts[2]);
          
          if (month != null && day != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
    }
    return null;
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

  void _handleNavigation(int index) {
    if (_selectedNavIndex != index) {
      setState(() => _selectedNavIndex = index);
    }
  }

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
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.black),
            SizedBox(height: 16),
            Text(
              'Loading bookings...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            SizedBox(height: 16),
            Text(
              'Not logged in',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please log in to view your bookings',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Booking>>(
      future: _bookingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  'Error loading bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _bookingFuture = BookingService.getMyBookings(userId!);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return BookingEmptyStateWidget(
            onBrowseCars: () {
              Navigator.pushNamed(context, '/renters');
            },
          );
        }

        // OPTIMIZED: Update badge counts from the fetched data
        final allBookings = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _updateBadgeCountsFromBookings(allBookings);
            });
          }
        });

        final bookings = _filterBookings(allBookings);

        if (bookings.isEmpty) {
          return BookingEmptyStateWidget(
            onBrowseCars: () {
              Navigator.pushNamed(context, '/renters');
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _bookingFuture = BookingService.getMyBookings(userId!);
            });
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BookingCardWidget(
                  booking: bookings[index],
                  status: _mapStatusForUI(bookings[index].status),
                  onReviewSubmitted: () {
                    setState(() {
                      _bookingFuture = BookingService.getMyBookings(userId!);
                    });
                  },
                ),
              );
            },
          ),
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
      tabs: _tabLabels,
      badgeCounts: [_activeCount, _pendingCount, _pastCount],
    );
  }
}