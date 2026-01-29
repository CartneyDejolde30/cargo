// lib/USERS-UI/Renter/bookings/history/my_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'booking_card_widget.dart';
import 'booking_empty_state_widget.dart';
import 'booking_tabs_widget.dart';
import 'package:flutter_application_1/USERS-UI/Renter/widgets/bottom_nav_bar.dart';
import 'package:flutter_application_1/USERS-UI/Renter/models/booking.dart';
import 'package:flutter_application_1/USERS-UI/services/booking_service.dart';
import 'package:flutter_application_1/USERS-UI/Renter/payments/refund_history_screen.dart';

// GPS Tracking imports
import 'package:flutter_application_1/USERS-UI/services/renter_gps_service.dart';
import 'package:flutter_application_1/USERS-UI/widgets/location_permission_helper.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;

  int _currentTabIndex = 0;
  int _selectedNavIndex = 1;

  Future<List<Booking>>? _bookingFuture;
  
  String? userId;
  bool _isLoading = true;

  // Badge counts for each tab
  int _activeCount = 0;
  int _pendingCount = 0;
  int _completedCount = 0;
  int _rejectedCount = 0;

  // GPS Service
  final RenterGpsService _gpsService = renterGpsService;
  bool _hasCheckedGpsTracking = false;
  bool _isCheckingGps = false; // ✅ NEW: Prevent concurrent GPS checks

  // Tab labels
  final List<String> _tabLabels = ['Active', 'Pending', 'Completed', 'Rejected'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    _loadUserIdAndFetchBookings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Continue GPS tracking even when app goes to background
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed, checking GPS tracking status...');
      // Only restart if tracking was active and now stopped
      if (!_gpsService.isTracking && _hasCheckedGpsTracking && !_isCheckingGps) {
        _hasCheckedGpsTracking = false; // Reset to allow recheck
        _autoStartGpsForActiveBookings();
      }
    }
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

  // ✅ FIXED: Better GPS tracking initialization with safeguards
  Future<void> _autoStartGpsForActiveBookings() async {
    // Prevent multiple concurrent calls
    if (_isCheckingGps) {
      debugPrint('⏸️ GPS check already in progress, skipping');
      return;
    }

    if (_hasCheckedGpsTracking) {
      debugPrint('ℹ️ GPS tracking already checked');
      return;
    }

    try {
      _isCheckingGps = true;
      debugPrint('🔍 Checking for active bookings to start GPS tracking...');

      final bookings = await _bookingFuture;
      if (bookings == null || bookings.isEmpty) {
        debugPrint('ℹ️ No bookings found');
        _hasCheckedGpsTracking = true;
        return;
      }

      final now = DateTime.now();
      
      // Find active bookings
      final activeBookings = bookings.where((b) {
        if (b.status.toLowerCase() != 'approved') return false;
        final pickup = _parseDate(b.pickupDate);
        final returnDate = _parseDate(b.returnDate);
        return pickup != null && returnDate != null && 
               !pickup.isAfter(now) && !returnDate.isBefore(now);
      }).toList();

      if (activeBookings.isEmpty) {
        debugPrint('ℹ️ No active bookings found');
        _hasCheckedGpsTracking = true;
        return;
      }

      debugPrint('📍 Found ${activeBookings.length} active booking(s)');

      // Check if already tracking one of these bookings
      final firstActiveBooking = activeBookings.first;
      if (_gpsService.isTracking && 
          _gpsService.activeBookingId == firstActiveBooking.bookingId.toString()) {
        debugPrint('✅ Already tracking booking ${firstActiveBooking.bookingId}');
        _hasCheckedGpsTracking = true;
        return;
      }

      // Start GPS for the first active booking
      debugPrint('🚀 Auto-starting GPS for booking: ${firstActiveBooking.bookingId}');

      // Check permissions first
      if (!mounted) {
        _hasCheckedGpsTracking = true;
        return;
      }
      
      final hasPermission = await LocationPermissionHelper.showPermissionDialog(context);
      
      if (!hasPermission) {
        debugPrint('❌ Location permission not granted');
        _hasCheckedGpsTracking = true;
        return;
      }

      // Start tracking
      final success = await _gpsService.startTracking(
        firstActiveBooking.bookingId.toString()
      );

      _hasCheckedGpsTracking = true;

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.gps_fixed,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GPS tracking started for ${firstActiveBooking.carName}',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,

            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _currentTabIndex = 0; // Switch to Active tab
                    _tabController.animateTo(0);
                  });
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error auto-starting GPS: $e');
      _hasCheckedGpsTracking = true;
    } finally {
      _isCheckingGps = false;
    }
  }

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
    
    _completedCount = bookings.where((b) => b.status == 'completed').length;
    
    _rejectedCount = bookings.where((b) => 
      b.status == 'rejected' || b.status == 'cancelled'
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

  void _onTabChanged() {
    if (_currentTabIndex != _tabController.index) {
      if (mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    }
  }

  List<Booking> _filterBookings(List<Booking> all) {
    switch (_currentTabIndex) {
      case 0: // Active
        return all.where((b) => b.status == 'approved').toList();

      case 1: // Pending
        return all.where((b) => b.status == 'pending').toList();

      case 2: // Completed
        return all.where((b) => b.status == 'completed').toList();

      case 3: // Rejected (NEWEST → OLDEST)
        final rejected = all.where((b) =>
          b.status.toLowerCase() == 'cancelled' ||
          b.status.toLowerCase() == 'rejected'
        ).toList();

        // Sort by pickup date (newest first)
        rejected.sort((a, b) {
          final dateA = _parseDate(a.pickupDate);
          final dateB = _parseDate(b.pickupDate);

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA); // DESC = newest first
        });

        return rejected;

      default:
        return [];
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final normalized = dateStr.trim().replaceFirst(' ', 'T');
      return DateTime.parse(normalized);
    } catch (e) {
      print("❌ Date parse failed: $dateStr");
      return null;
    }
  }

  String _mapStatusForUI(String status) {
    switch (status) {
      case 'approved':
        return 'active';
      case 'pending':
        return 'pending';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      case 'rejected':
        return 'rejected';
      default:
        return 'pending';
    }
  }

  void _handleNavigation(int index) {
    if (_selectedNavIndex != index) {
      if (mounted) {
        setState(() => _selectedNavIndex = index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'My Bookings',
        style: GoogleFonts.poppins(
          color: Theme.of(context).iconTheme.color,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      actions: [
        // GPS Status Indicator
        if (_gpsService.isTracking)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LocationPermissionHelper.buildGpsStatusBadge(
              isTracking: _gpsService.isTracking,
              successCount: _gpsService.successCount,
              failCount: _gpsService.failCount,
              lastUpdate: _gpsService.lastUpdate,
            ),
          ),
        
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RefundHistoryScreen(),
              ),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,

              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    Icons.undo,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),

                const SizedBox(width: 6),
                Text(
                  'Refunds',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBookingBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),

            SizedBox(height: 16),
            Text(
              'Loading bookings...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,

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
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error,),
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
                color: Theme.of(context).colorScheme.outline,
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
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error,),
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
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _bookingFuture = BookingService.getMyBookings(userId!);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,

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

        final allBookings = snapshot.data!;
        
        // ✅ FIXED: Only auto-start GPS once after data loads
        if (!_hasCheckedGpsTracking && !_isCheckingGps) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updateBadgeCountsFromBookings(allBookings);
              _autoStartGpsForActiveBookings();
            }
          });
        } else {
          // Just update badge counts without GPS check
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _updateBadgeCountsFromBookings(allBookings);
              });
            }
          });
        }

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
            if (mounted) {
              setState(() {
                _bookingFuture = BookingService.getMyBookings(userId!);
                _hasCheckedGpsTracking = false; // Reset to check again
                _isCheckingGps = false;
              });
            }
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
                    if (mounted) {
                      setState(() {
                        _bookingFuture = BookingService.getMyBookings(userId!);
                        _hasCheckedGpsTracking = false;
                        _isCheckingGps = false;
                      });
                    }
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
      badgeCounts: [_activeCount, _pendingCount, _completedCount, _rejectedCount],
    );
  }
}