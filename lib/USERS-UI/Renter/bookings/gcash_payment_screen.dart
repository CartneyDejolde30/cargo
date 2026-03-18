import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cargo/config/api_config.dart';

class GCashPaymentScreen extends StatefulWidget {
  final int bookingId;
  final String vehicleType;
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
  final double baseRental;
  final double discount;
  final double insurancePremium;
  final double totalAmount;
  final double serviceFee;
  final double securityDeposit;

  const GCashPaymentScreen({
    super.key,
    required this.bookingId,
    required this.vehicleType,
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
    required this.baseRental,
    this.discount = 0.0,
    this.insurancePremium = 0.0,
    required this.totalAmount,
    required this.serviceFee,
    this.securityDeposit = 0.0,
  });

  @override
  State<GCashPaymentScreen> createState() => _GCashPaymentScreenState();
}

class _GCashPaymentScreenState extends State<GCashPaymentScreen> {
  final TextEditingController gcashNumberController = TextEditingController();
  final TextEditingController referenceNumberController = TextEditingController();

  bool _isLoading = false;
  bool hasAgreedToTerms = false;
  
  String? _transactionId;

  final String gcashQRCodeUrl = "assets/qr.jpg";
  final String baseUrl = GlobalApiConfig.baseUrl + "/";

  @override
  void initState() {
    super.initState();
    // Manual GCash payment - no automatic status checking needed
  }

  @override
  void dispose() {
    gcashNumberController.dispose();
    referenceNumberController.dispose();
    super.dispose();
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
                'Amount: ${_formatCurrency(widget.totalAmount + widget.securityDeposit)}',
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
    // ✅ FIX: Remove all non-digit characters before validation
    final gcashRaw = gcashNumberController.text.trim();
    final gcash = gcashRaw.replaceAll(RegExp(r'\D'), ''); // Remove all non-digits
    
    final refRaw = referenceNumberController.text.trim();
    final ref = refRaw.replaceAll(RegExp(r'\D'), ''); // Remove all non-digits

    // Validate GCash number (must be exactly 11 digits starting with 09)
    if (!RegExp(r'^09\d{9}$').hasMatch(gcash)) {
      _showError('Invalid GCash number (must be 11 digits starting with 09)');
      return false;
    }

    // Validate reference number (must be exactly 13 digits)
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

    setState(() => _isLoading = true);

    final cleanGcash = gcashNumberController.text.trim().replaceAll(RegExp(r'\D'), '');
    final cleanRef = referenceNumberController.text.trim().replaceAll(RegExp(r'\D'), '');

    try {
      // Step 1: Create the booking
      final bookingResponse = await http.post(
        Uri.parse(GlobalApiConfig.createBookingEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "user_id": widget.userId,
          "vehicle_type": widget.vehicleType,
          "vehicle_id": widget.carId.toString(),
          "full_name": widget.fullName,
          "email": widget.email,
          "contact": widget.contact,
          "pickup_date": widget.pickupDate,
          "return_date": widget.returnDate,
          "pickup_time": widget.pickupTime,
          "return_time": widget.returnTime,
          "rental_period": widget.rentalPeriod,
          "needs_delivery": widget.needsDelivery ? "1" : "0",
          "insurance_premium": widget.insurancePremium.toStringAsFixed(2),
          "total_amount": widget.totalAmount.toStringAsFixed(2),
        },
      ).timeout(const Duration(seconds: 15));

      if (bookingResponse.statusCode != 200) {
        throw Exception('Booking creation failed: ${bookingResponse.statusCode}');
      }

      final bookingData = jsonDecode(bookingResponse.body);
      if (bookingData['success'] != true) {
        throw Exception(bookingData['message'] ?? 'Booking creation failed');
      }

      final bookingId = int.tryParse('${bookingData['data']?['booking_id'] ?? ''}');
      if (bookingId == null) {
        throw Exception('Invalid response: missing booking_id');
      }

      // Step 2: Submit payment
      final paymentResponse = await http.post(
        Uri.parse(GlobalApiConfig.submitPaymentEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "booking_id": bookingId.toString(),
          "car_id": widget.carId.toString(),
          "owner_id": widget.ownerId,
          "user_id": widget.userId,
          "total_amount": (widget.totalAmount + widget.securityDeposit).toStringAsFixed(2),
          "payment_method": "gcash",
          "gcash_number": cleanGcash,
          "payment_reference": cleanRef,
        },
      );

      if (paymentResponse.statusCode != 200) {
        throw Exception('Server error: ${paymentResponse.statusCode}');
      }

      final data = jsonDecode(paymentResponse.body);

      if (mounted) {
        setState(() => _isLoading = false);

        if (data['success'] == true) {
          _transactionId = data['transaction_id']?.toString();
          _showSuccessDialog();
        } else {
          _showError(data['message'] ?? 'Payment submission failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: ${e.toString()}');
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

  void _showSuccessDialog() {
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
              'Payment Submitted!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment has been received and will be verified manually by our admin team.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            
            // Transaction ID Display
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
                 backgroundColor: Theme.of(context).iconTheme.color,




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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GCash Payment',
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,



            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
            color: Colors.blue.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.9),
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
    final grandTotal = widget.totalAmount + widget.securityDeposit;
    
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
            color: const Color(0xFF007DFF).withValues(alpha: 0.3),
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
                child: const Icon(Icons.payment, color: Color(0xFF007DFF)),
              ),
              const Spacer(),
              Text(
                'Total to Pay',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(grandTotal),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rental & Insurance: ${_formatCurrency(widget.totalAmount)} + Deposit: ${_formatCurrency(widget.securityDeposit)}',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
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
          _buildCopyableField('Amount', _formatCurrency(widget.totalAmount + widget.securityDeposit)),
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
    // ✅ FIX: Add input formatters to only allow digits
    final List<TextInputFormatter> inputFormatters = [
      FilteringTextInputFormatter.digitsOnly, // Only allow digits
    ];
    
    // Add max length based on field
    if (label.contains('GCash Number')) {
      inputFormatters.add(LengthLimitingTextInputFormatter(11)); // Max 11 digits
    } else if (label.contains('Reference')) {
      inputFormatters.add(LengthLimitingTextInputFormatter(13)); // Max 13 digits
    }
    
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
          inputFormatters: inputFormatters,
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
            // ✅ FIX: Add counter to show character count
            counterText: label.contains('GCash') ? '11 digits' : '13 digits',
            counterStyle: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
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
          activeColor: Theme.of(context).iconTheme.color,

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
    final grandTotal = widget.totalAmount + widget.securityDeposit;

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
          // --- Booking Details ---
          Text(
            'Booking Summary',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Car', widget.carName),
          _buildSummaryRow('Rental Period', widget.rentalPeriod),
          _buildSummaryRow('Pickup Date', widget.pickupDate),
          _buildSummaryRow('Return Date', widget.returnDate),
          if (widget.needsDelivery) _buildSummaryRow('Delivery', 'Yes'),

          const Divider(height: 24),

          // --- Price Breakdown ---
          Text(
            'Price Breakdown',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          _buildSummaryRow('Base Rental', _formatCurrency(widget.baseRental)),

          if (widget.discount > 0)
            _buildSummaryRow(
              '${widget.rentalPeriod} Discount',
              '-${_formatCurrency(widget.discount)}',
              valueColor: Colors.green.shade700,
            ),

          if (widget.insurancePremium > 0)
            _buildSummaryRow('Insurance Premium', _formatCurrency(widget.insurancePremium)),

          _buildSummaryRow(
            'Service Fee (5%)',
            _formatCurrency(widget.serviceFee),
            valueColor: Colors.grey.shade700,
          ),

          const Divider(height: 16),

          _buildSummaryRow(
            'Total Amount',
            _formatCurrency(widget.totalAmount),
            isBold: true,
          ),

          const SizedBox(height: 8),

          // Security Deposit row with orange highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Security Deposit (20%)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(widget.securityDeposit),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Text(
            'Refundable after successful vehicle return',
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
          ),

          const Divider(height: 20, thickness: 1.5),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatCurrency(grandTotal),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isBold ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? (isBold ? Colors.black : null),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              colors: _isLoading || !hasAgreedToTerms
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [const Color(0xFF1a73e8), const Color(0xFF0d47a1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isLoading || !hasAgreedToTerms)
                    ? Colors.grey.withValues(alpha: 0.3)
                    : const Color(0xFF1a73e8).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (_isLoading || !hasAgreedToTerms) ? null : _submitPayment,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: _isLoading
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