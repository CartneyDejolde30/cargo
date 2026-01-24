import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/USERS-UI/Renter/models/booking.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.black),
          ),
          onPressed: () => _showMoreOptions(),
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
                child: const Icon(Icons.directions_car, size: 80),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
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
    final DateTime pickupDate = _parseDate(widget.booking.pickupDate) ?? DateTime.now();
    final DateTime returnDate = _parseDate(widget.booking.returnDate) ?? DateTime.now();
    final DateTime now = DateTime.now();
    
    final int totalDays = returnDate.difference(pickupDate).inDays;
    final int daysRemaining = returnDate.difference(now).inDays;
    final int hoursRemaining = returnDate.difference(now).inHours % 24;
    
    final double progress = totalDays > 0 ? (totalDays - daysRemaining) / totalDays : 0;

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
              color: Colors.blue.withOpacity(0.3),
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
                      daysRemaining > 0
                          ? '$daysRemaining days $hoursRemaining hrs left'
                          : '$hoursRemaining hours left',
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
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pickup',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Return',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.booking.pickupDate,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      widget.booking.returnDate,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tab Selector
  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
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
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
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
                  'Extend Trip',
                  Icons.calendar_month,
                  Colors.blue,
                  () => _showExtendDialog(),
                ),
              ),
              const SizedBox(width: 12),
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
          _buildNavigationButton(
            'Share Location',
            Icons.share_location,
            Colors.green,
            () => _shareLocation(),
          ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
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
                  backgroundColor: Colors.black,
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
        ),
      ),
    );
  }

  // Helper Methods
  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr.replaceFirst(' ', 'T'));
    } catch (e) {
      return null;
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
              leading: const Icon(Icons.calendar_month),
              title: const Text('Extend Booking'),
              onTap: () {
                Navigator.pop(context);
                _showExtendDialog();
              },
            ),
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

  void _showExtendDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Extend trip feature coming soon!'),
        backgroundColor: Colors.blue,
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
    final url = 'https://www.google.com/maps/search/?api=1&query=$location';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share location feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _contactOwner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${widget.booking.ownerName}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _callOwner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.booking.ownerName}...'),
        backgroundColor: Colors.green,
      ),
    );
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