import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cargo/USERS-UI/Renter/models/booking.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cargo/USERS-UI/Renter/chats/chat_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cargo/USERS-UI/Renter/bookings/map_route_screen.dart';
import 'package:cargo/widgets/optimized_network_image.dart';

class LiveTripTrackerScreen extends StatefulWidget {
  final Booking booking;

  const LiveTripTrackerScreen({
    super.key,
    required this.booking,
  });

  @override
  State<LiveTripTrackerScreen> createState() => _LiveTripTrackerScreenState();
}

class _LiveTripTrackerScreenState extends State<LiveTripTrackerScreen> {
  int _selectedTabIndex = 0;


Future<String> _getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("user_id") ?? "";
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildTripStatusCard(),
                const SizedBox(height: 20),
                _buildTabSelector(),
                const SizedBox(height: 20),
                _buildTabContent(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  // App Bar with car image
  SliverAppBar _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration:  BoxDecoration(
            color: isDark ? colors.surface : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: colors.onSurface),

        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration:  BoxDecoration(
              color: isDark ? colors.surface : Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white),

          ),
          onPressed: () => _showMoreOptions(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedNetworkImage(
              imageUrl: widget.booking.carImage,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorIcon: Icons.directions_car,
              errorIconSize: 80,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booking.carName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                     color: Colors.white,
                    ),
                  ),
                  Text(
                    'Booking #${widget.booking.bookingId}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
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

  // Trip Status Card
  Widget _buildTripStatusCard() {
    // Parse full return datetime (date + time) to avoid midnight-only parsing bug
    final DateTime returnDate = _parseDateTimeStr(
      widget.booking.returnDate,
      widget.booking.returnTime,
    ) ?? DateTime.now();
    final DateTime now = DateTime.now();

    final Duration timeLeft = returnDate.difference(now);
    final bool isOverdue = timeLeft.isNegative;
    final int daysRemaining = isOverdue ? 0 : timeLeft.inDays;
    final int hoursRemaining = isOverdue ? 0 : timeLeft.inHours % 24;
    final int minutesRemaining = isOverdue ? 0 : timeLeft.inMinutes % 60;

    String timeLabel;
    if (isOverdue) {
      timeLabel = 'Overdue';
    } else if (daysRemaining > 0) {
      timeLabel = '$daysRemaining days $hoursRemaining hrs left';
    } else if (hoursRemaining > 0) {
      timeLabel = '$hoursRemaining hrs $minutesRemaining min left';
    } else {
      timeLabel = '$minutesRemaining min left';
    }

    return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade600, Colors.blue.shade800],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip in Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white, // ✅ always light
                size: 32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Date row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
                ),
                Text(
                  widget.booking.pickupDate,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Return',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
                ),
                Text(
                  widget.booking.returnDate,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Milestone Stepper
        _buildRenterMilestoneStepper(),
      ],
    ),
  ),
);

  }

  // Tab Selector
  Widget _buildTabSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
         color: isDark ? colors.surfaceContainerHighest : Colors.grey.shade100,

          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTab('Overview', 0, Icons.dashboard),
            _buildTab('Location', 1, Icons.map),
            _buildTab('Support', 2, Icons.help_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
    ? (isDark ? colors.primary : Colors.black)
    : Colors.transparent,

            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab Content
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildLocationTab();
      case 2:
        return _buildSupportTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // Overview Tab
  Widget _buildOverviewTab() {
   

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pickup Info
          _buildInfoCard(
            'Pickup Location',
            widget.booking.location,
            '${widget.booking.pickupDate} • ${widget.booking.pickupTime}',
            Icons.arrow_circle_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          
          // Return Info
          _buildInfoCard(
            'Return Location',
            widget.booking.location,
            '${widget.booking.returnDate} • ${widget.booking.returnTime}',
            Icons.arrow_circle_down,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Report Issue',
                  Icons.report_problem,
                  Colors.red,
                  () => _showReportDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Location Tab
  Widget _buildLocationTab() {
   

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navigation',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Map placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Map integration coming soon',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Navigation buttons
          _buildNavigationButton(
            'Navigate to Pickup Location',
            Icons.navigation,
            Colors.blue,
            () => _openMaps(widget.booking.location),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Support Tab
  Widget _buildSupportTab() {
  
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Help?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSupportCard(
            'Contact Car Owner',
            widget.booking.ownerName,
            'Available 24/7',
            Icons.person,
            Colors.blue,
            () => _contactOwner(),
          ),
          const SizedBox(height: 12),
          
          _buildSupportCard(
            'Emergency Support',
            'carGO Support Team',
            'Response time: 5-10 mins',
            Icons.support_agent,
            Colors.red,
            () => _callSupport(),
          ),
          const SizedBox(height: 12),
          
          _buildSupportCard(
            'Roadside Assistance',
            '24/7 Emergency Service',
            'Available nationwide',
            Icons.local_hospital,
            Colors.orange,
            () => _callRoadside(),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildInfoCard(
    String title,
    String location,
    String dateTime,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
       
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateTime,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
   
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    String title,
    String subtitle,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          

        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
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

  // Bottom Actions
  Widget _buildBottomActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _contactOwner(),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  'Message',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).iconTheme.color,


                  side: BorderSide(color: isDark ? colors.outline : Colors.black),

                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callOwner(),
                icon: const Icon(Icons.phone),
                label: Text(
                  'Call Owner',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                   backgroundColor: isDark ? colors.primary : Colors.black,
                  foregroundColor: isDark ? colors.onPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Milestone Stepper
  Widget _buildRenterMilestoneStepper() {
    final isCompleted = widget.booking.status == 'completed';
    final isOngoing = widget.booking.status == 'ongoing';
    final tripStarted = isOngoing || widget.booking.tripStarted;
    final odometerStart = widget.booking.odometerStart;

    // activeStep: index of the step currently in progress (steps before it are done)
    // 0=Confirmed, 1=Picked Up, 2=In Progress, 3=Completed
    // Action-based: advances when owner starts the trip (status=ongoing or trip_started flag)
    final int activeStep;
    if (isCompleted) {
      activeStep = 4; // all done
    } else if (tripStarted || odometerStart != null) {
      activeStep = 2; // In Progress is current
    } else {
      activeStep = 1; // Picked Up is current, Confirmed done
    }

    final steps = [
      _TripMilestone('Confirmed', Icons.check_circle_outline),
      _TripMilestone('Picked Up', Icons.directions_car),
      _TripMilestone('In Progress', Icons.route),
      _TripMilestone('Completed', Icons.flag),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildStepperChildren(steps, activeStep),
    );
  }

  List<Widget> _buildStepperChildren(List<_TripMilestone> steps, int activeStep) {
    final result = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      final isDone = i < activeStep;
      final isCurrent = i == activeStep;
      result.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? Colors.green
                    : isCurrent
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                border: isCurrent
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check : steps[i].icon,
                size: 14,
                color: isDone
                    ? Colors.white
                    : isCurrent
                        ? Colors.blue.shade700
                        : Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              steps[i].label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: isCurrent || isDone ? FontWeight.w600 : FontWeight.w400,
                color: isDone || isCurrent ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      );
      if (i < steps.length - 1) {
        result.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 19),
              child: Container(
                height: 2,
                color: i < activeStep
                    ? Colors.green
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      }
    }
    return result;
  }

  // Helper Methods
  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr.replaceFirst(' ', 'T'));
    } catch (e) {
      return null;
    }
  }

  /// Parses a date string + time string into a full DateTime.
  /// Avoids the midnight-only bug when time is stored in a separate field.
  DateTime? _parseDateTimeStr(String dateStr, String timeStr) {
    try {
      final d = dateStr.trim();
      final t = timeStr.trim().isNotEmpty ? timeStr.trim() : '00:00:00';
      return DateTime.parse('${d}T$t');
    } catch (_) {
      return _parseDate(dateStr);
    }
  }

  void _showMoreOptions() {
    

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel Trip'),
              onTap: () {
                Navigator.pop(context);
                _showCancelDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report issue feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Trip?'),
        content: Text('Are you sure you want to cancel this ongoing trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle cancellation
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _openMaps(String location) async {
    // Use coordinates from booking if available
    final lat = widget.booking.latitude;
    final lng = widget.booking.longitude;
    
    if (lat != null && lng != null) {
      // Navigate to MapRouteScreen with MapTiler
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapRouteScreen(
            destinationLat: lat,
            destinationLng: lng,
            locationName: location,
            carName: widget.booking.carName,
          ),
        ),
      );
    } else {
      // Fallback: Show error or use external maps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location coordinates not available for this vehicle.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Use External Map',
            onPressed: () => _openExternalMaps(location),
          ),
        ),
      );
    }
  }
  
  void _openExternalMaps(String location) async {
    // Fallback option: Open in external maps app
    final url = 'https://www.google.com/maps/search/?api=1&query=$location';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}


 Future<void> _contactOwner() async {
  final currentUserId = await _getCurrentUserId();

  if (currentUserId.isEmpty) {
    _showError("User not logged in");
    return;
  }

  final ownerId = widget.booking.ownerId;
  final bookingId = widget.booking.bookingId;

  // Generate consistent chat ID
  final chatId = bookingId.toString().compareTo(currentUserId) < 0
      ? "${bookingId}_$currentUserId\_$ownerId"
      : "${bookingId}_$ownerId\_$currentUserId";

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatDetailScreen(
        chatId: chatId,
        peerId: ownerId.toString(),
        peerName: widget.booking.ownerName,
        peerAvatar: widget.booking.ownerAvatar, // make sure this exists
      ),
    ),
  );
}


 Future<void> _callOwner() async {
  final phone = widget.booking.ownerPhone;

  if (phone.isEmpty) {
    _showError("Owner phone number not available");
    return;
  }

  final uri = Uri.parse("tel:$phone");

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    _showError("Could not open phone dialer");
  }
}


  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling emergency support...'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _callRoadside() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling roadside assistance...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class _TripMilestone {
  final String label;
  final IconData icon;
  const _TripMilestone(this.label, this.icon);
}