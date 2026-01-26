import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaymentStatusTracker extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onRequestRefund;

  const PaymentStatusTracker({
    super.key,
    required this.paymentData,
    this.onViewReceipt,
    this.onRequestRefund,
  });

  @override
  Widget build(BuildContext context) {
    final paymentStatus = paymentData['payment_status'] ?? 'pending';
    final escrowStatus = paymentData['escrow_status'] ?? 'none';
    final hasEscrow = escrowStatus != 'none' && escrowStatus.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Status Header
        _buildSectionHeader(context,'Payment Status', Icons.payment),
        const SizedBox(height: 16),
        
        // Payment Status Card
        _buildPaymentStatusCard(context,paymentStatus),
        
        // Escrow Information (if applicable)
        if (hasEscrow) ...[
          const SizedBox(height: 16),
          _buildSectionHeader(context,'Escrow Status', Icons.lock_clock),
          const SizedBox(height: 16),
          _buildEscrowStatusCard(escrowStatus),
        ],

        // Transaction Timeline
        const SizedBox(height: 24),
        _buildSectionHeader(context,'Transaction Timeline', Icons.timeline),
        const SizedBox(height: 16),
        _buildTransactionTimeline(),

        // Action Buttons
        const SizedBox(height: 20),
        _buildActionButtons(paymentStatus, context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context,String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).iconTheme.color,



          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCard(BuildContext context,String status) {
    final statusInfo = _getPaymentStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusInfo['color'].withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusInfo['icon'],
                  color: statusInfo['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusInfo['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).iconTheme.color,



                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusInfo['subtitle'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusInfo['color'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
            child: Column(
              children: [
                _buildInfoRow('Amount', _formatCurrency(paymentData['amount'])),
                const SizedBox(height: 8),
                _buildInfoRow('Method', paymentData['payment_method']?.toString().toUpperCase() ?? 'N/A'),
                if (paymentData['payment_reference'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Reference', paymentData['payment_reference']),
                ],
                const SizedBox(height: 8),
                _buildInfoRow('Date', _formatDate(paymentData['created_at'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowStatusCard(String escrowStatus) {
    final statusInfo = _getEscrowStatusInfo(escrowStatus);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusInfo['color'].withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusInfo['color'].withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusInfo['icon'],
                color: statusInfo['color'],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusInfo['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusInfo['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (paymentData['escrow_amount'] != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Held Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  _formatCurrency(paymentData['escrow_amount']),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: statusInfo['color'],
                  ),
                ),
              ],
            ),
          ],
          if (paymentData['expected_release_date'] != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expected Release',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  _formatDate(paymentData['expected_release_date']),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionTimeline() {
    final timeline = _buildTimelineEvents();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: timeline.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final isLast = index == timeline.length - 1;
          
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
      ),
    );
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
                    color: isCompleted ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
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

  Widget _buildActionButtons(String status, BuildContext context) {
    return Column(
      children: [
        if (status.toLowerCase() == 'verified' || status.toLowerCase() == 'completed') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewReceipt,
              icon: const Icon(Icons.receipt_long, size: 20),
              label: Text(
                'View Receipt',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                 backgroundColor: Theme.of(context).iconTheme.color,




                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
        if (status.toLowerCase() == 'failed' || status.toLowerCase() == 'rejected') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRequestRefund,
              icon: const Icon(Icons.undo, size: 20),
              label: Text(
                'Request Refund',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _buildTimelineEvents() {
    final paymentStatus = paymentData['payment_status'] ?? 'pending';
    final events = <Map<String, dynamic>>[];

    // Payment Submitted
    events.add({
      'icon': Icons.payment,
      'title': 'Payment Submitted',
      'subtitle': 'Your payment has been received',
      'timestamp': _formatDate(paymentData['created_at']),
      'color': Colors.blue,
      'isCompleted': true,
    });

    // Payment Verification
    if (['verified', 'completed', 'escrow_held', 'escrow_released'].contains(paymentStatus.toLowerCase())) {
      events.add({
        'icon': Icons.verified_user,
        'title': 'Payment Verified',
        'subtitle': 'Payment has been confirmed by admin',
        'timestamp': _formatDate(paymentData['verified_at']),
        'color': Colors.green,
        'isCompleted': true,
      });
    } else {
      events.add({
        'icon': Icons.hourglass_empty,
        'title': 'Awaiting Verification',
        'subtitle': 'Admin is verifying your payment',
        'timestamp': null,
        'color': Colors.orange,
        'isCompleted': false,
      });
    }

    // Escrow Hold (if applicable)
    final escrowStatus = paymentData['escrow_status'] ?? '';
    if (escrowStatus == 'held' || escrowStatus == 'released') {
      events.add({
        'icon': Icons.lock,
        'title': 'Funds Held in Escrow',
        'subtitle': 'Payment secured until booking completion',
        'timestamp': _formatDate(paymentData['escrow_held_at']),
        'color': Colors.blue.shade700,
        'isCompleted': true,
      });
    }

    // Escrow Release / Payment Complete
    if (escrowStatus == 'released' || paymentStatus.toLowerCase() == 'completed') {
      events.add({
        'icon': Icons.check_circle,
        'title': 'Payment Released',
        'subtitle': 'Funds transferred to owner',
        'timestamp': _formatDate(paymentData['escrow_released_at'] ?? paymentData['completed_at']),
        'color': Colors.green.shade600,
        'isCompleted': true,
      });
    }

    return events;
  }

  Map<String, dynamic> _getPaymentStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'completed':
        return {
          'title': 'Payment Successful',
          'subtitle': 'Your payment has been verified and processed',
          'icon': Icons.check_circle,
          'color': Colors.green.shade600,
        };
      case 'pending':
        return {
          'title': 'Payment Pending',
          'subtitle': 'Awaiting admin verification',
          'icon': Icons.hourglass_empty,
          'color': Colors.orange.shade600,
        };
      case 'failed':
      case 'rejected':
        return {
          'title': 'Payment Failed',
          'subtitle': 'Payment could not be processed',
          'icon': Icons.cancel,
          'color': Colors.red.shade600,
        };
      case 'escrow_held':
        return {
          'title': 'Payment Held',
          'subtitle': 'Funds secured in escrow',
          'icon': Icons.lock_clock,
          'color': Colors.blue.shade700,
        };
      case 'refunded':
        return {
          'title': 'Payment Refunded',
          'subtitle': 'Refund has been processed',
          'icon': Icons.undo,
          'color': Colors.purple.shade600,
        };
      default:
        return {
          'title': 'Payment Status Unknown',
          'subtitle': 'Please contact support',
          'icon': Icons.help,
          'color': Colors.grey.shade600,
        };
    }
  }

  Map<String, dynamic> _getEscrowStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'held':
        return {
          'title': 'Funds in Escrow',
          'description': 'Payment is securely held until booking completion',
          'icon': Icons.account_balance_wallet,
          'color': Colors.blue.shade700,
        };
      case 'released':
        return {
          'title': 'Funds Released',
          'description': 'Payment has been transferred to the owner',
          'icon': Icons.check_circle_outline,
          'color': Colors.green.shade600,
        };
      case 'cancelled':
        return {
          'title': 'Escrow Cancelled',
          'description': 'Funds have been returned',
          'icon': Icons.cancel_outlined,
          'color': Colors.red.shade600,
        };
      default:
        return {
          'title': 'Escrow Active',
          'description': 'Your payment is being processed',
          'icon': Icons.access_time,
          'color': Colors.orange.shade600,
        };
    }
  }

  String _formatCurrency(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    ).format(value);
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }
}