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
  String? _errorMessage;

  final String baseUrl = "http://192.168.1.11/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}api/receipts/generate_receipt.php?booking_id=${widget.bookingId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _receiptData = data;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load receipt');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _downloadReceipt() async {
    if (_receiptData == null || _receiptData!['receipt_url'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt download not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final url = Uri.parse(_receiptData!['receipt_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _emailReceipt() async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}api/receipts/send_receipt_email.php'),
        body: {
          'booking_id': widget.bookingId.toString(),
        },
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['success'] == true
                  ? 'Receipt sent to your email!'
                  : data['message'] ?? 'Failed to send email',
            ),
            backgroundColor: data['success'] == true ? Colors.green : Colors.red,
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
          'Payment Receipt',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _receiptData != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'download') {
                  _downloadReceipt();
                } else if (value == 'email') {
                  _emailReceipt();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      const Icon(Icons.download, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Download PDF',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'email',
                  child: Row(
                    children: [
                      const Icon(Icons.email, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Email Receipt',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildReceiptContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Receipt',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReceipt,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    // Mock receipt data structure - adjust based on your actual API response
    final receiptNo = _receiptData?['receipt_no'] ?? 'RCP-000000';
    final bookingId = '#BK-${widget.bookingId.toString().padLeft(4, '0')}';
    final dateIssued = DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now());
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Receipt Container
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CarGo',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PAYMENT RECEIPT',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Receipt Information
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt Details
                      _buildSectionTitle('Receipt Information'),
                      const SizedBox(height: 16),
                      _buildInfoRow('Receipt No:', receiptNo),
                      _buildInfoRow('Booking ID:', bookingId),
                      _buildInfoRow('Date Issued:', dateIssued),
                      _buildInfoRow('Status:', 'PAID', valueColor: Colors.green.shade700),

                      const SizedBox(height: 32),

                      // Payment Summary
                      _buildSectionTitle('Payment Summary'),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow('Base Rental Fee', '₱5,000.00'),
                            const SizedBox(height: 12),
                            _buildSummaryRow('Service Fee', '₱250.00'),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              'Total Amount',
                              '₱5,250.00',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Payment Method
                      _buildSectionTitle('Payment Details'),
                      const SizedBox(height: 16),
                      _buildInfoRow('Payment Method:', 'GCash'),
                      _buildInfoRow('Reference:', '1234567890123'),

                      const SizedBox(height: 32),

                      // Footer Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Important Notice',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is a computer-generated receipt and does not require a signature. Keep this receipt for your records.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.blue.shade900,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _emailReceipt,
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: Text(
                      'Email',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadReceipt,
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(
                      'Download',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
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
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }
}