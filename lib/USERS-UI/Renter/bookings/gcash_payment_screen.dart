import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GCashPaymentScreen extends StatefulWidget {
  final int bookingId;
  final int carId;
  final String carName;
  final String carImage;
  final String ownerId;
  final String userId;
  final String fullName;
  final String email;
  final String contact;
  final String pickupDate;
  final String returnDate;
  final String pickupTime;
  final String returnTime;
  final String rentalPeriod;
  final bool needsDelivery;
  final double totalAmount;
  
  final String? paymentIntentId;
  final String? clientKey;

  const GCashPaymentScreen({
    super.key,
    required this.bookingId,
    required this.carId,
    required this.carName,
    required this.carImage,
    required this.ownerId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.contact,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.returnTime,
    required this.rentalPeriod,
    required this.needsDelivery,
    required this.totalAmount,
    this.paymentIntentId,
    this.clientKey,
  });

  @override
  State<GCashPaymentScreen> createState() => _GCashPaymentScreenState();
}

class _GCashPaymentScreenState extends State<GCashPaymentScreen> {
  final TextEditingController gcashNumberController = TextEditingController();
  final TextEditingController referenceNumberController = TextEditingController();

  bool isProcessing = false;
  bool hasAgreedToTerms = false;
  
  // 🆕 Payment Intent Tracking
  String? _transactionId;
  String? _paymentIntentStatus;
  bool _isCheckingStatus = false;

  final String gcashQRCodeUrl = "assets/gcash.jpg";
  final String baseUrl = "http://10.244.29.49/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    // 🆕 Check payment intent status if available
    if (widget.paymentIntentId != null) {
      _checkPaymentIntentStatus();
    }
  }

  @override
  void dispose() {
    gcashNumberController.dispose();
    referenceNumberController.dispose();
    super.dispose();
  }

  // 🆕 Check Payment Intent Status
  Future<void> _checkPaymentIntentStatus() async {
    if (widget.paymentIntentId == null) return;

    setState(() => _isCheckingStatus = true);

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}api/payment/check_payment_intent.php?payment_intent_id=${widget.paymentIntentId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _paymentIntentStatus = data['status'];
            _transactionId = data['transaction_id'];
          });

          // Auto-redirect if payment already succeeded
          if (data['status'] == 'succeeded') {
            _showSuccessDialog(showAutoDetected: true);
          }
        }
      }
    } catch (e) {
      print('Error checking payment intent: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    ).format(amount);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan to Pay',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Image.asset(
                gcashQRCodeUrl,
                height: 260,
                width: 260,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                'Amount: ${_formatCurrency(widget.totalAmount)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    final gcash = gcashNumberController.text.trim();
    final ref = referenceNumberController.text.trim();

    if (!RegExp(r'^09\d{9}$').hasMatch(gcash)) {
      _showError('Invalid GCash number (must be 09XXXXXXXXX)');
      return false;
    }

    if (!RegExp(r'^\d{13}$').hasMatch(ref)) {
      _showError('Reference number must be exactly 13 digits');
      return false;
    }

    if (!hasAgreedToTerms) {
      _showError('Please agree to the terms and conditions');
      return false;
    }

    return true;
  }

  Future<void> _submitPayment() async {
    if (!_validateForm()) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}api/submit_payment.php"),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "booking_id": widget.bookingId.toString(),
          "car_id": widget.carId.toString(),
          "owner_id": widget.ownerId,
          "user_id": widget.userId,
          "total_amount": widget.totalAmount.toStringAsFixed(2),
          "payment_method": "gcash",
          "gcash_number": gcashNumberController.text.trim(),
          "payment_reference": referenceNumberController.text.trim(),
          if (widget.paymentIntentId != null) 
            "payment_intent_id": widget.paymentIntentId!,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() => isProcessing = false);

        if (data['success'] == true) {
          // 🆕 Store transaction ID
          _transactionId = data['transaction_id']?.toString();
          _showSuccessDialog();
        } else {
          _showError(data['message'] ?? 'Payment submission failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        _showError('Network error: ${e.toString()}');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessDialog({bool showAutoDetected = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              showAutoDetected ? 'Payment Detected!' : 'Payment Submitted!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              showAutoDetected 
                  ? 'Your payment has been automatically detected and verified.'
                  : 'Your payment has been received and is being verified by our admin team.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            
            // 🆕 Transaction ID Display
            if (_transactionId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Transaction ID',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _transactionId!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _copyToClipboard(_transactionId!, 'Transaction ID'),
                          icon: const Icon(Icons.copy, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: Colors.blue.shade700, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can track your payment status in the Payment History section.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to booking screen
                Navigator.pop(context); // Return to main screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GCash Payment',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isCheckingStatus
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.black),
                  const SizedBox(height: 16),
                  Text(
                    'Checking payment status...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : Column(
        children: [
          // 🆕 Payment Intent Status Banner
          if (_paymentIntentStatus != null && _paymentIntentStatus != 'succeeded')
            Container(
              padding: const EdgeInsets.all(12),
              color: _getStatusColor(_paymentIntentStatus!).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(_paymentIntentStatus!),
                    color: _getStatusColor(_paymentIntentStatus!),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusMessage(_paymentIntentStatus!),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getStatusColor(_paymentIntentStatus!),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountCard(),
                  const SizedBox(height: 24),
                  _buildShowQRButton(),
                  const SizedBox(height: 24),
                  _buildInstructions(),
                  const SizedBox(height: 24),
                  _buildGCashAccountDetails(),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: gcashNumberController,
                    label: 'Your GCash Number',
                    hint: '09XX XXX XXXX',
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: referenceNumberController,
                    label: 'GCash Reference Number',
                    hint: 'Enter the 13-digit reference number',
                    icon: Icons.receipt_long,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 24),
                  _buildBookingSummary(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // 🆕 Helper methods for payment intent status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Colors.green;
      case 'processing':
      case 'awaiting_payment_method':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Payment is being processed. Please complete the transaction.';
      case 'awaiting_payment_method':
        return 'Waiting for payment confirmation. Please complete your GCash payment.';
      case 'failed':
        return 'Previous payment attempt failed. Please try again.';
      case 'cancelled':
        return 'Payment was cancelled. You can submit a new payment.';
      default:
        return 'Payment status: $status';
    }
  }

  Widget _buildShowQRButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showQRDialog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View QR Code',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tap to view and scan GCash QR',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007DFF), Color(0xFF0052CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007DFF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/5/5c/GCash_logo.png',
                  height: 24,
                  errorBuilder: (_, __, ___) => const Icon(Icons.payment, color: Color(0xFF007DFF)),
                ),
              ),
              const Spacer(),
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(widget.totalAmount),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Philippine Peso',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'How to Pay',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Tap "View QR Code" button above'),
          _buildInstructionStep('2', 'Open GCash app and tap "Scan QR"'),
          _buildInstructionStep('3', 'Scan the QR code displayed'),
          _buildInstructionStep('4', 'Complete payment in GCash app'),
          _buildInstructionStep('5', 'Enter your details and 13-digit reference number below'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGCashAccountDetails() {
    const String gcashName = "CarGO Rentals";
    const String gcashNumber = "09123456789";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Payment To:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          _buildCopyableField('Account Name', gcashName),
          const SizedBox(height: 12),
          _buildCopyableField('GCash Number', gcashNumber),
          const SizedBox(height: 12),
          _buildCopyableField('Amount', _formatCurrency(widget.totalAmount)),
        ],
      ),
    );
  }

  Widget _buildCopyableField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(value, label),
          icon: const Icon(Icons.copy, size: 18),
          color: Colors.blue.shade700,
          tooltip: 'Copy',
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: hasAgreedToTerms,
          onChanged: (value) {
            setState(() => hasAgreedToTerms = value ?? false);
          },
          activeColor: Colors.black,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => hasAgreedToTerms = !hasAgreedToTerms);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'I confirm that I have completed the GCash payment and agree to the terms and conditions',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Booking ID', '#BK-${widget.bookingId}'),
          _buildSummaryRow('Car', widget.carName),
          _buildSummaryRow('Rental Period', widget.rentalPeriod),
          _buildSummaryRow('Pickup Date', widget.pickupDate),
          _buildSummaryRow('Return Date', widget.returnDate),
          _buildSummaryRow('Delivery', widget.needsDelivery ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
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
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isProcessing || !hasAgreedToTerms
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [const Color(0xFF1a73e8), const Color(0xFF0d47a1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isProcessing || !hasAgreedToTerms)
                    ? Colors.grey.withOpacity(0.3)
                    : const Color(0xFF1a73e8).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (isProcessing || !hasAgreedToTerms) ? null : _submitPayment,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing Payment...',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Confirm Payment',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}