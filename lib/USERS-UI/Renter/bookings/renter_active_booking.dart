// lib/USERS-UI/Renter/bookings/renter_active_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/renter_gps_service.dart';
import '../../Owner/mycar/api_config.dart';

class RenterActiveBookingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const RenterActiveBookingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<RenterActiveBookingScreen> createState() => _RenterActiveBookingScreenState();
}

class _RenterActiveBookingScreenState extends State<RenterActiveBookingScreen> 
    with WidgetsBindingObserver {
  
  bool _isTrackingActive = false;
  String _lastUpdateTime = 'Never';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startGpsTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    renterGpsService.stopTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Continue tracking even in background
    if (state == AppLifecycleState.resumed) {
      if (!renterGpsService.isTracking) {
        _startGpsTracking();
      }
    }
  }

  Future<void> _startGpsTracking() async {
    try {
      final bookingId = widget.booking['id']?.toString() ?? 
                       widget.booking['booking_id']?.toString();
      
      if (bookingId == null) {
        debugPrint('❌ No booking ID found');
        return;
      }

      debugPrint('🚀 Starting GPS tracking for booking: $bookingId');
      
      await renterGpsService.startTracking(bookingId);
      
      if (mounted) {
        setState(() {
          _isTrackingActive = true;
          _lastUpdateTime = 'Just now';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  'GPS tracking started',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to start GPS tracking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start GPS tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _manualLocationUpdate() async {
    final bookingId = widget.booking['id']?.toString() ?? 
                     widget.booking['booking_id']?.toString();
    
    if (bookingId == null) return;

    final success = await renterGpsService.sendManualUpdate(bookingId);
    
    if (mounted) {
      setState(() {
        _lastUpdateTime = 'Just now';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                success ? 'Location updated' : 'Update failed',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.getCarImageUrl(
      widget.booking['car_image'] ?? widget.booking['image']
    );
    final carName = widget.booking['car_full_name'] ?? 
                   widget.booking['car_name'] ?? 
                   'Vehicle';
    final daysRemaining = int.tryParse(
      widget.booking['days_remaining']?.toString() ?? '0'
    ) ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Active Rental',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // GPS Status Indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isTrackingActive 
                  ? Colors.green.shade100 
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isTrackingActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isTrackingActive ? 'Tracking' : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isTrackingActive 
                        ? Colors.green.shade700 
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),

            // Car Name
            Text(
              carName,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Days Remaining
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: daysRemaining <= 1 
                    ? Colors.red.shade50 
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: daysRemaining <= 1 
                        ? Colors.red.shade700 
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$daysRemaining day${daysRemaining != 1 ? 's' : ''} remaining',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: daysRemaining <= 1 
                          ? Colors.red.shade700 
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // GPS Tracking Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isTrackingActive
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.red.shade50, Colors.red.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isTrackingActive 
                      ? Colors.green.shade200 
                      : Colors.red.shade200,
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
                          color: _isTrackingActive 
                              ? Colors.green 
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.gps_fixed,
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
                              _isTrackingActive
                                  ? 'Your location is being shared with the owner'
                                  : 'GPS tracking is currently offline',
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
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last Update:',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _lastUpdateTime,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _manualLocationUpdate,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(
                        'Update Location Now',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
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

            const SizedBox(height: 24),

            // Booking Details
            _buildSection('Rental Details', [
              _buildDetailRow('Pickup Date', widget.booking['pickup_date'] ?? 'N/A'),
              _buildDetailRow('Return Date', widget.booking['return_date'] ?? 'N/A'),
              _buildDetailRow('Total Amount', '₱${widget.booking['total_amount'] ?? '0'}'),
              _buildDetailRow('Status', widget.booking['status'] ?? 'N/A'),
            ]),

            const SizedBox(height: 20),

            // Important Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GPS tracking is active during your rental. The owner can see your vehicle\'s location.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}