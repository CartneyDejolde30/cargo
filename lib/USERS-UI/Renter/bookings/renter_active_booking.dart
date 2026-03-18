// lib/USERS-UI/Renter/bookings/renter_active_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/renter_gps_service.dart';
import '../../Owner/mycar/api_config.dart';
import '../insurance/insurance_policy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cargo/widgets/optimized_network_image.dart';
import 'package:cargo/USERS-UI/widgets/odometer_input_screen.dart';

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
    try {
      renterGpsService.stopTracking();
    } catch (_) {}
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Active Rental',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).iconTheme.color,


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
              child: OptimizedNetworkImage(
                imageUrl: imageUrl.trim().isEmpty ? 'https://via.placeholder.com/300' : imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(16),
                errorIcon: Icons.directions_car,
                errorIconSize: 80,
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
                         backgroundColor: Theme.of(context).iconTheme.color,




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

            // Odometer Tracking Section
            _buildOdometerSection(),

            const SizedBox(height: 24),

            // Insurance Policy Button
            _buildInsurancePolicyButton(),

            const SizedBox(height: 24),

            // Booking Details
            _buildSection('Rental Details', [
              _buildDetailRow('Pickup Date', widget.booking['pickup_date'] ?? 'N/A'),
              _buildDetailRow('Return Date', widget.booking['return_date'] ?? 'N/A'),
              _buildDetailRow('Status', widget.booking['status'] ?? 'N/A'),
              const Divider(height: 20),
              if ((widget.booking['base_rental'] as num? ?? 0) > 0)
                _buildDetailRow('Base Rental', '₱${(widget.booking['base_rental'] as num).toStringAsFixed(2)}'),
              if ((widget.booking['discount'] as num? ?? 0) > 0)
                _buildDetailRow('Discount', '-₱${(widget.booking['discount'] as num).toStringAsFixed(2)}'),
              if ((widget.booking['insurance_premium'] as num? ?? 0) > 0)
                _buildDetailRow('Insurance Premium', '₱${(widget.booking['insurance_premium'] as num).toStringAsFixed(2)}'),
              if ((widget.booking['service_fee'] as num? ?? 0) > 0)
                _buildDetailRow('Service Fee (5%)', '₱${(widget.booking['service_fee'] as num).toStringAsFixed(2)}'),
              _buildDetailRow('Total Amount', '₱${widget.booking['total_amount'] ?? '0'}'),
              if ((widget.booking['security_deposit'] as num? ?? 0) > 0)
                _buildDetailRow('Security Deposit (20%)', '₱${(widget.booking['security_deposit'] as num).toStringAsFixed(2)}'),
              const Divider(height: 20),
              _buildDetailRow(
                'Grand Total',
                '₱${(widget.booking['grand_total'] as num? ?? 0) > 0 ? (widget.booking['grand_total'] as num).toStringAsFixed(2) : widget.booking['total_amount'] ?? '0'}',
              ),
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

  Widget _buildInsurancePolicyButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.shade200,
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
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield,
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
                      'Insurance Coverage',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View your policy details and file claims',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _viewInsurancePolicy,
              icon: const Icon(Icons.description, size: 18),
              label: Text(
                'View Insurance Policy',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
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
    );
  }

  Widget _buildOdometerSection() {
    final odometerStart = widget.booking['odometer_start'];
    final odometerEnd = widget.booking['odometer_end'];
    final startPhoto = widget.booking['odometer_start_photo'];
    final endPhoto = widget.booking['odometer_end_photo'];
    final tripStarted = widget.booking['trip_started'] == 1 || widget.booking['trip_started'] == '1';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.speed,
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
                      'Odometer Tracking',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record mileage at pickup and return',
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
          
          const SizedBox(height: 20),
          
          // Start Odometer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Starting Odometer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (odometerStart != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Recorded',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        odometerStart != null ? '$odometerStart km' : 'Not recorded',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: odometerStart != null ? Colors.black : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    if (odometerStart == null && !tripStarted)
                      ElevatedButton.icon(
                        onPressed: _recordStartOdometer,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: Text(
                          'Record',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
                if (startPhoto != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OptimizedNetworkImage(
                      imageUrl: '${ApiConfig.uploadsUrl}/odometer/$startPhoto',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // End Odometer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ending Odometer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (odometerEnd != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Recorded',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        odometerEnd != null ? '$odometerEnd km' : 'Not recorded',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: odometerEnd != null ? Colors.black : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    if (odometerEnd == null && tripStarted && odometerStart != null)
                      ElevatedButton.icon(
                        onPressed: _recordEndOdometer,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: Text(
                          'Record',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
                if (endPhoto != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OptimizedNetworkImage(
                      imageUrl: '${ApiConfig.uploadsUrl}/odometer/$endPhoto',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Distance traveled
          if (odometerStart != null && odometerEnd != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Distance',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${((odometerEnd as num?)?.toInt() ?? 0) - ((odometerStart as num?)?.toInt() ?? 0)} km',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _recordStartOdometer() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final bookingId = widget.booking['id'] ?? widget.booking['booking_id'];
    final vehicleName = widget.booking['car_full_name'] ?? 
                       widget.booking['car_name'] ?? 
                       'Vehicle';
    final vehicleImage = widget.booking['car_image'] ?? widget.booking['image'] ?? '';
    
    if (bookingId == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => OdometerInputScreen(
          bookingId: int.parse(bookingId.toString()),
          vehicleName: vehicleName,
          vehicleImage: vehicleImage,
          isStartOdometer: true,
          userId: userId,
          userType: 'renter',
        ),
      ),
    );

    if (result != null && mounted) {
      // Refresh the screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start odometer recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Trigger a refresh by popping and showing message to parent
      Navigator.pop(context, true);
    }
  }

  Future<void> _recordEndOdometer() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final bookingId = widget.booking['id'] ?? widget.booking['booking_id'];
    final vehicleName = widget.booking['car_full_name'] ?? 
                       widget.booking['car_name'] ?? 
                       'Vehicle';
    final vehicleImage = widget.booking['car_image'] ?? widget.booking['image'] ?? '';
    final startOdometer = int.tryParse(widget.booking['odometer_start']?.toString() ?? '0');
    
    if (bookingId == null || startOdometer == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => OdometerInputScreen(
          bookingId: int.parse(bookingId.toString()),
          vehicleName: vehicleName,
          vehicleImage: vehicleImage,
          isStartOdometer: false,
          startOdometer: startOdometer,
          userId: userId,
          userType: 'renter',
        ),
      ),
    );

    if (result != null && mounted) {
      // Refresh the screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End odometer recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Trigger a refresh by popping and showing message to parent
      Navigator.pop(context, true);
    }
  }

  Future<void> _viewInsurancePolicy() async {
    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get booking ID
      final bookingId = widget.booking['id'] ?? widget.booking['booking_id'];
      
      if (bookingId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking ID not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Navigate to Insurance Policy Screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InsurancePolicyScreen(
              bookingId: bookingId is int ? bookingId : int.parse(bookingId.toString()),
              userId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}