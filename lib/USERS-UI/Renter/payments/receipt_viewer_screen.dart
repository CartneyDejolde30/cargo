import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceiptViewerScreen extends StatefulWidget {
  final int bookingId;

  const ReceiptViewerScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _receiptData;
  String? _error;

  final String baseUrl = "http://10.77.127.2/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    _fetchReceipt();
  }

  Future<void> _fetchReceipt() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse("${baseUrl}api/receipts/get_receipt.php?booking_id=${widget.bookingId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          setState(() {
            _receiptData = result['receipt'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['message'] ?? 'Failed to load receipt';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReceipt() async {
    if (_receiptData == null) return;

    try {
      final receiptUrl = _receiptData!['receipt_url'];
      final url = Uri.parse(receiptUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Cannot open receipt', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to download receipt', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Receipt',
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,



            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _receiptData != null)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.black),
              onPressed: _downloadReceipt,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildReceiptContent(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load receipt',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchReceipt,
            style: ElevatedButton.styleFrom(
               backgroundColor: Theme.of(context).iconTheme.color,




              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('Retry', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    if (_receiptData == null) return const SizedBox();

    final receiptNo = _receiptData!['receipt_no'] ?? 'N/A';
    final bookingId = _receiptData!['booking_id'] ?? 'N/A';
    final dateIssued = _receiptData!['created_at'] ?? '';
    final status = _receiptData!['status'] ?? 'PAID';

    // Renter info
    final renterName = _receiptData!['renter_name'] ?? 'N/A';
    final renterEmail = _receiptData!['renter_email'] ?? 'N/A';
    final renterContact = _receiptData!['renter_contact'] ?? 'N/A';

    // Rental details
    final carName = _receiptData!['car_name'] ?? 'N/A';
    final pickupDate = _receiptData!['pickup_date'] ?? '';
    final returnDate = _receiptData!['return_date'] ?? '';
    final duration = _receiptData!['duration'] ?? 'N/A';

    // Payment details
    final amount = double.tryParse(_receiptData!['amount'].toString()) ?? 0;
    final paymentMethod = _receiptData!['payment_method'] ?? 'N/A';
    final paymentReference = _receiptData!['payment_reference'] ?? 'N/A';

    return Column(
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).iconTheme.color,



            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'CarGo',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PAYMENT RECEIPT',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Receipt Information
        _buildSection(
          title: 'Receipt Information',
          children: [
            _buildInfoRow('Receipt No', receiptNo),
            _buildInfoRow('Booking ID', '#BK-$bookingId'),
            _buildInfoRow('Date Issued', _formatDateTime(dateIssued)),
          ],
        ),

        const SizedBox(height: 16),

        // Renter Information
        _buildSection(
          title: 'Renter Information',
          children: [
            _buildInfoRow('Name', renterName),
            _buildInfoRow('Email', renterEmail),
            _buildInfoRow('Contact', renterContact),
          ],
        ),

        const SizedBox(height: 16),

        // Rental Details
        _buildSection(
          title: 'Rental Details',
          children: [
            _buildInfoRow('Vehicle', carName),
            _buildInfoRow('Pickup Date', _formatDate(pickupDate)),
            _buildInfoRow('Return Date', _formatDate(returnDate)),
            _buildInfoRow('Duration', duration),
          ],
        ),

        const SizedBox(height: 16),

        // Payment Summary
        _buildSection(
          title: 'Payment Summary',
          children: [
            _buildInfoRow('Total Amount', '₱${amount.toStringAsFixed(2)}', isHighlighted: true),
            _buildInfoRow('Payment Method', paymentMethod.toUpperCase()),
            _buildInfoRow('Reference', paymentReference),
          ],
        ),

        const SizedBox(height: 32),

        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Thank you for choosing CarGo!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).iconTheme.color,



                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This is a computer-generated receipt and does not require a signature.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Download Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Icons.download),
            label: Text(
              'Download Receipt',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
               backgroundColor: Theme.of(context).iconTheme.color,




              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).iconTheme.color,



            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted ? Colors.green.shade700 : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}