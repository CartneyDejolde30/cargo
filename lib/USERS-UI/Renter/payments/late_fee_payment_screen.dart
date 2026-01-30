import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../bookings/gcash_payment_screen.dart';

class LateFeePaymentScreen extends StatefulWidget {
  final int bookingId;
  final double rentalAmount;
  final double lateFee;
  final int hoursOverdue;
  final String vehicleName;

  const LateFeePaymentScreen({
    Key? key,
    required this.bookingId,
    required this.rentalAmount,
    required this.lateFee,
    required this.hoursOverdue,
    required this.vehicleName,
  }) : super(key: key);

  @override
  State<LateFeePaymentScreen> createState() => _LateFeePaymentScreenState();
}

class _LateFeePaymentScreenState extends State<LateFeePaymentScreen> {
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  double get _totalAmount => widget.rentalAmount + widget.lateFee;
  int get _daysOverdue => (widget.hoursOverdue / 24).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Overdue Payment',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[700]!, Colors.red[900]!],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vehicle Overdue',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_daysOverdue day(s) past return date',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info Card
                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  // Late Fee Breakdown
                  _buildLateFeeBreakdown(),
                  const SizedBox(height: 20),

                  // Payment Summary
                  _buildPaymentSummary(),
                  const SizedBox(height: 30),

                  // Important Notice
                  _buildImportantNotice(),
                  const SizedBox(height: 30),

                  // Pay Now Button
                  _buildPayButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Vehicle', widget.vehicleName),
          _buildDetailRow('Booking ID', '#${widget.bookingId}'),
          _buildDetailRow('Hours Overdue', '${widget.hoursOverdue} hours'),
          _buildDetailRow('Days Overdue', '$_daysOverdue day(s)'),
        ],
      ),
    );
  }

  Widget _buildLateFeeBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Late Fee Breakdown',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeeRow('Grace Period', '2 hours', 'FREE'),
          _buildFeeRow('Tier 1 (2-6 hours)', '₱300/hour', null),
          _buildFeeRow('Tier 2 (6-24 hours)', '₱500/hour', null),
          _buildFeeRow('Tier 3 (1+ days)', '₱2,000/day', null),
          const Divider(height: 24),
          _buildFeeRow(
            'Your Late Fee',
            '$_daysOverdue day(s)',
            '₱${widget.lateFee.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Original Rental', widget.rentalAmount, false),
          _buildSummaryRow('Late Fee', widget.lateFee, false),
          const Divider(color: Colors.white24, height: 24),
          _buildSummaryRow('Total Amount Due', _totalAmount, true),
        ],
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Important',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Payment must include both rental fee and late charges\n'
            '• Failure to pay may result in account suspension\n'
            '• Late fees continue to accumulate until payment\n'
            '• Contact support if you need payment assistance',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.orange[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₱${_totalAmount.toStringAsFixed(2)} Now',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
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
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String tier, String rate, String? amount,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              tier,
              style: GoogleFonts.inter(
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.red[900] : Colors.red[800],
              ),
            ),
          ),
          Text(
            amount ?? rate,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.red[900] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontSize: isTotal ? 24 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_userId == null) {
      _showErrorDialog('Please log in to make payment');
      return;
    }

    // Navigate to GCash payment screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GCashPaymentScreen(
          bookingId: widget.bookingId,
          amount: _totalAmount,
          isLateFeePayment: true,
        ),
      ),
    );

    if (result == true && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            Text('Payment Submitted', style: GoogleFonts.outfit()),
          ],
        ),
        content: Text(
          'Your payment including late fees has been submitted for verification. '
          'You will be notified once approved.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 12),
            Text('Error', style: GoogleFonts.outfit()),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
