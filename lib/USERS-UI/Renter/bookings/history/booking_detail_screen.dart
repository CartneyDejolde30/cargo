// lib/USERS-UI/Renter/bookings/history/booking_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/USERS-UI/Renter/models/booking.dart';
import 'package:flutter_application_1/USERS-UI/services/booking_service.dart';
import 'package:flutter_application_1/USERS-UI/Renter/payments/payment_status_tracker.dart';
import 'package:flutter_application_1/USERS-UI/Renter/payments/receipt_viewer_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/payments/refund_request_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/bookings/history/live_trip_tracker_screen.dart';
import 'package:flutter_application_1/USERS-UI/services/renter_gps_service.dart';
import 'package:flutter_application_1/USERS-UI/widgets/location_permission_helper.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;
  final String status;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.status,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  String? userId;
  bool _isLoading = true;
  bool _isLoadingPayment = true;
  Map<String, dynamic>? _paymentData;
  bool _bookingChanged = false;
  
  // GPS Tracking
  final RenterGpsService _gpsService = renterGpsService;
  bool _isGpsTracking = false;

  final String baseUrl = "http://10.244.29.49/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    _loadUserIdAndPayment();
    _checkAndStartGpsTracking();
  }

  @override
  void dispose() {
    // Only stop GPS if booking is not active anymore
    if (widget.booking.status.toLowerCase() != 'approved') {
      _gpsService.stopTracking();
    }
    super.dispose();
  }

  Future<void> _checkAndStartGpsTracking() async {
    // Start GPS only for approved/active bookings
    if (widget.booking.status.toLowerCase() == 'approved' ||
        widget.status.toLowerCase() == 'active') {
      await _startGpsTracking();
    }
  }

  Future<void> _startGpsTracking() async {
    debugPrint('🚀 Checking GPS tracking for booking: ${widget.booking.bookingId}');

    // Check if already tracking this booking
    if (_gpsService.isTracking && 
        _gpsService.activeBookingId == widget.booking.bookingId.toString()) {
      debugPrint('✓ Already tracking this booking');
      setState(() => _isGpsTracking = true);
      return;
    }

    // Request permissions
    final hasPermission = await LocationPermissionHelper.showPermissionDialog(context);
    
    if (!hasPermission) {
      debugPrint('❌ Location permission not granted');
      return;
    }

    // Start tracking
    final success = await _gpsService.startTracking(widget.booking.bookingId.toString());

    if (mounted) {
      setState(() => _isGpsTracking = success);

      if (success) {
        debugPrint('✅ GPS tracking started successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GPS tracking started for your rental',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _stopGpsTracking() {
    debugPrint('🛑 Stopping GPS tracking');
    _gpsService.stopTracking();
    
    if (mounted) {
      setState(() => _isGpsTracking = false);
    }
  }

  Future<void> _loadUserIdAndPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedUserId = prefs.getString('user_id');
    
    setState(() {
      userId = loadedUserId;
      _isLoading = false;
    });

    await _fetchPaymentInfo();
  }

  Future<void> _fetchPaymentInfo() async {
    setState(() => _isLoadingPayment = true);

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}api/payment/get_booking_payment.php?booking_id=${widget.booking.bookingId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['payment'] != null) {
          setState(() {
            _paymentData = data['payment'];
          });
        }
      }
    } catch (e) {
      print('Error fetching payment info: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPayment = false);
      }
    }
  }

  String _getStatusText() {
    switch (widget.booking.status.toLowerCase()) {
      case 'approved':
        return 'Active';
      case 'pending':
        return 'Pending Payment';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return widget.booking.status;
    }
  }

  Color _getStatusColor() {
    switch (widget.booking.status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red.shade400;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildContent(context)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: _circleIcon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context, _bookingChanged),
      ),
      actions: [
        // GPS Status Indicator for Active Bookings
        if (widget.status.toLowerCase() == 'active')
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LocationPermissionHelper.buildGpsStatusBadge(
              isTracking: _isGpsTracking,
              successCount: _gpsService.successCount,
              failCount: _gpsService.failCount,
              lastUpdate: _gpsService.lastUpdate,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.booking.carImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.directions_car, size: 100),
              ),
            ),
            _imageGradient(),
            _statusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _carInfo(),
        _rentalPeriod(),
        const SizedBox(height: 20),
        
        // GPS Tracking Section - Only for Active Bookings
        if (widget.status.toLowerCase() == 'active') ...[
          _buildGpsTrackingSection(),
          const SizedBox(height: 20),
        ],
        
        _locationCard(),
        const SizedBox(height: 20),
        
        // Payment Status Section
        if (_paymentData != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PaymentStatusTracker(
              paymentData: _paymentData!,
              onViewReceipt: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptViewerScreen(
                      bookingId: widget.booking.bookingId,
                    ),
                  ),
                );
              },
              onRequestRefund: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RefundRequestScreen(
                      bookingId: widget.booking.bookingId,
                      bookingReference: '#BK-${widget.booking.bookingId}',
                      totalAmount: double.tryParse(_paymentData!['amount'].toString()) ?? 0,
                      cancellationDate: DateTime.now().toString(),
                      paymentMethod: _paymentData!['payment_method'] ?? 'N/A',
                      paymentReference: _paymentData!['payment_reference'] ?? 'N/A',
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    _fetchPaymentInfo();
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 20),
        ] else if (_isLoadingPayment) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        _paymentDetails(),
        const SizedBox(height: 20),
        _helpSection(),
        const SizedBox(height: 120),
      ],
    );
  }

  // NEW: GPS Tracking Section
  Widget _buildGpsTrackingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isGpsTracking
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.orange.shade50, Colors.orange.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isGpsTracking 
                ? Colors.green.shade200 
                : Colors.orange.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isGpsTracking ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isGpsTracking ? Icons.gps_fixed : Icons.gps_off,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Tracking',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isGpsTracking
                            ? 'Your location is being shared with the owner'
                            : 'Start GPS tracking to share your location',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (_isGpsTracking) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.cloud_upload, 
                              size: 20, color: Colors.green.shade700),
                          const SizedBox(height: 4),
                          Text(
                            '${_gpsService.successCount}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Updates Sent',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, 
                              size: 20, color: Colors.red.shade700),
                          const SizedBox(height: 4),
                          Text(
                            '${_gpsService.failCount}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Failed',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGpsTracking ? _stopGpsTracking : _startGpsTracking,
                icon: Icon(
                  _isGpsTracking ? Icons.location_off : Icons.location_on,
                  size: 18,
                ),
                label: Text(
                  _isGpsTracking ? 'Stop GPS Tracking' : 'Start GPS Tracking',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isGpsTracking 
                      ? Colors.red.shade600 
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.booking.carName,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.receipt_long, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Booking ID: ${widget.booking.bookingId}',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rentalPeriod() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Rental Period',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _dateCard(
                    'Pick Up',
                    widget.booking.pickupDate,
                    widget.booking.pickupTime,
                    Icons.arrow_circle_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _dateCard(
                    'Return',
                    widget.booking.returnDate,
                    widget.booking.returnTime,
                    Icons.arrow_circle_down,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    // Show refund button for rejected/cancelled
    if (widget.booking.status == 'rejected' || widget.booking.status == 'cancelled') {
      return _buildRefundButton(context);
    }

    switch (widget.status) {
      case 'active':
        return _twoButtons(
          context,
          'Cancel Booking',
          Colors.red,
          _showCancelDialog,
          'View Trip',
          Colors.black,
          rightAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveTripTrackerScreen(
                  booking: widget.booking,
                ),
              ),
            );
          },
        );

      case 'pending':
        return ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Awaiting owner approval...'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Awaiting Approval',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );

      case 'upcoming':
        return _twoButtons(
          context,
          'Modify Booking',
          Colors.grey,
          _showCancelDialog,
          'Get Directions',
          Colors.black,
          rightAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveTripTrackerScreen(
                  booking: widget.booking,
                ),
              ),
            );
          },
        );

      case 'past':
      case 'completed':
        return _singleButton(
          'Book This Car Again',
          Colors.black,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                content: Text('Rebooking feature coming soon!'),
                 backgroundColor: Theme.of(context).iconTheme.color,




              ),
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _locationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            _iconBox(Icons.location_on, Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking.location,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _paymentDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Breakdown',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _paymentRow('Rental Fee', '₱${widget.booking.totalPrice}'),
                const Divider(height: 24),
                _paymentRow('Service Fee', '₱250', isSubtotal: true),
                const Divider(height: 24),
                _paymentRow(
                  'Total Amount',
                  '₱${_calculateTotal(widget.booking.totalPrice)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Help?',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  'Message Owner',
                  Icons.chat_bubble_outline,
                  Colors.blue,
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contactButton(
                  'Call Support',
                  Icons.phone,
                  Colors.green,
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: _buildBottomButton(context)),
    );
  }

  Widget _buildRefundButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.booking.status == 'rejected'
                      ? 'This booking was rejected by the owner'
                      : 'This booking was cancelled',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RefundRequestScreen(
                    bookingId: widget.booking.bookingId,
                    bookingReference: '#BK-${widget.booking.bookingId.toString().padLeft(4, '0')}',
                    totalAmount: double.tryParse(
                          widget.booking.totalPrice.replaceAll(',', ''),
                        ) ?? 0,
                    cancellationDate: DateTime.now().toString(),
                    paymentMethod: _paymentData?['payment_method'] ?? 'gcash',
                    paymentReference: _paymentData?['payment_reference'] ?? widget.booking.bookingId.toString(),
                  ),
                ),
              );

              if (result == true) {
                await _fetchPaymentInfo();
              }
            },
            icon: const Icon(Icons.undo, size: 20),
            label: Text(
              'Request Refund',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  String _calculateTotal(String fee) {
    final value = int.tryParse(fee.replaceAll(',', '')) ?? 0;
    return (value + 250).toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  void _showCancelDialog(BuildContext context) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? GPS tracking will be stopped. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.black),
                        const SizedBox(height: 16),
                        Text(
                          'Cancelling booking...',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              // Stop GPS tracking
              _stopGpsTracking();

              final success = await BookingService.cancelBooking(
                bookingId: widget.booking.bookingId,
                userId: userId!,
              );

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking cancelled successfully. GPS tracking stopped.'),
                    backgroundColor: Colors.green,
                  ),
                );

                _bookingChanged = true;
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to cancel booking'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon),
      );

  Widget _imageGradient() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha((0.3 * 255).round())
            ],
          ),
        ),
      );

  Widget _statusBadge() => Positioned(
        top: 60,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          ),
        ),
      );

  Widget _iconBox(IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      );

  Widget _dateCard(
    String label,
    String date,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(date, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(time, style: GoogleFonts.poppins(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _paymentRow(
    String label,
    String value, {
    bool isSubtotal = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _contactButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _singleButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _twoButtons(
    BuildContext context,
    String leftLabel,
    Color leftColor,
    Function(BuildContext) leftAction,
    String rightLabel,
    Color rightColor, {
    VoidCallback? rightAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => leftAction(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: leftColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              leftLabel,
              style: GoogleFonts.poppins(
                color: leftColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: rightAction ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: rightColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              rightLabel,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}