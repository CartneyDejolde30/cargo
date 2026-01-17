import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Place this file in: lib/USERS-UI/Owner/transactions/payout_detail_screen.dart

class PayoutDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const PayoutDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Details',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsCard(),
            const SizedBox(height: 20),
            _buildVehicleInfo(),
            const SizedBox(height: 20),
            _buildRenterInfo(),
            const SizedBox(height: 20),
            _buildPaymentBreakdown(),
            const SizedBox(height: 20),
            _buildTimeline(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    final ownerPayout = double.tryParse(transaction['owner_payout'].toString()) ?? 0;
    final isCompleted = transaction['is_completed'] == true;
    final statusBadge = transaction['status_badge'] as Map<String, dynamic>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted 
            ? [Colors.green.shade700, Colors.green.shade900]
            : [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.green : Colors.blue).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Earnings',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusBadge['label']?.toString() ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(ownerPayout),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          _buildInfoItem(
            'Booking', 
            transaction['booking_reference'] ?? '#BK-${transaction['booking_id']}'
          ),
          const SizedBox(height: 8),
          _buildInfoItem('Booked On', transaction['booking_date_formatted'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    return _buildSection(
      title: 'Vehicle Information',
      icon: Icons.directions_car,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                transaction['vehicle_image'] ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: Icon(
                    transaction['vehicle_type'] == 'motorcycle' 
                      ? Icons.two_wheeler 
                      : Icons.directions_car,
                    color: Colors.grey.shade400,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['vehicle_name'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${transaction['vehicle_type']?.toString().toUpperCase() ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 12),
        _buildDetailRow('Pickup Date', _formatDate(transaction['pickup_date'])),
        const SizedBox(height: 8),
        _buildDetailRow('Return Date', _formatDate(transaction['return_date'])),
      ],
    );
  }

  Widget _buildRenterInfo() {
    return _buildSection(
      title: 'Renter Information',
      icon: Icons.person,
      children: [
        _buildDetailRow('Name', transaction['renter_name'] ?? 'N/A'),
        const SizedBox(height: 8),
        _buildDetailRow('Email', transaction['renter_email'] ?? 'N/A'),
        const SizedBox(height: 8),
        _buildDetailRow('Contact', transaction['renter_contact'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildPaymentBreakdown() {
    final totalAmount = double.tryParse(transaction['total_amount'].toString()) ?? 0;
    final platformFee = double.tryParse(transaction['platform_fee'].toString()) ?? 0;
    final ownerPayout = double.tryParse(transaction['owner_payout'].toString()) ?? 0;
    
    return _buildSection(
      title: 'Payment Breakdown',
      icon: Icons.receipt_long,
      children: [
        _buildAmountRow('Rental Fee', totalAmount),
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 12),
        _buildAmountRow(
          'Platform Fee (10%)', 
          platformFee,
          isDeduction: true,
        ),
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 12),
        _buildAmountRow(
          'Your Net Earnings', 
          ownerPayout,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final events = _buildTimelineEvents();
    
    return _buildSection(
      title: 'Transaction Timeline',
      icon: Icons.timeline,
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == events.length - 1;
        
        return _buildTimelineItem(
          event['icon'],
          event['title'],
          event['subtitle'],
          event['timestamp'],
          event['color'],
          isLast,
          event['isCompleted'],
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _buildTimelineEvents() {
    final events = <Map<String, dynamic>>[];
    
    // Booking Created
    events.add({
      'icon': Icons.event,
      'title': 'Booking Created',
      'subtitle': 'Rental request received',
      'timestamp': _formatDateTime(transaction['booking_date']),
      'color': Colors.blue,
      'isCompleted': true,
    });
    
    // Payment Received
    if (transaction['payment_date'] != null) {
      events.add({
        'icon': Icons.payment,
        'title': 'Payment Received',
        'subtitle': 'Renter paid ${_formatCurrency(double.tryParse(transaction['total_amount'].toString()) ?? 0)}',
        'timestamp': _formatDateTime(transaction['payment_date']),
        'color': Colors.green,
        'isCompleted': true,
      });
    }
    
    // Payment Verified
    if (transaction['payment_verified_at'] != null) {
      events.add({
        'icon': Icons.verified,
        'title': 'Payment Verified',
        'subtitle': 'Payment confirmed by admin',
        'timestamp': _formatDateTime(transaction['payment_verified_at']),
        'color': Colors.green,
        'isCompleted': true,
      });
    }
    
    // Funds in Escrow
    if (transaction['escrow_held_at'] != null) {
      events.add({
        'icon': Icons.lock,
        'title': 'Funds in Escrow',
        'subtitle': 'Payment secured until completion',
        'timestamp': _formatDateTime(transaction['escrow_held_at']),
        'color': Colors.blue.shade700,
        'isCompleted': true,
      });
    }
    
    // Payout Released
    if (transaction['escrow_released_at'] != null) {
      events.add({
        'icon': Icons.check_circle,
        'title': 'Payout Released',
        'subtitle': 'Earnings available to you',
        'timestamp': _formatDateTime(transaction['escrow_released_at']),
        'color': Colors.green.shade600,
        'isCompleted': true,
      });
    } else if (transaction['escrow_status'] == 'held') {
      events.add({
        'icon': Icons.hourglass_empty,
        'title': 'Awaiting Release',
        'subtitle': 'Will be released after rental completion',
        'timestamp': null,
        'color': Colors.orange,
        'isCompleted': false,
      });
    }
    
    return events;
  }

  Widget _buildTimelineItem(
    IconData icon,
    String title,
    String subtitle,
    String? timestamp,
    Color color,
    bool isLast,
    bool isCompleted,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? color : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? color.withOpacity(0.3) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timestamp,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isDeduction = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          '${isDeduction ? '-' : ''}${_formatCurrency(amount)}',
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal 
              ? Colors.green.shade700 
              : isDeduction 
                ? Colors.red.shade600 
                : Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    ).format(amount);
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }

  String _formatDateTime(dynamic dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }
}