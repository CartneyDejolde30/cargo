  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:intl/intl.dart';
  import 'dart:convert';
  import 'package:http/http.dart' as http;

  class GCashPaymentScreen extends StatefulWidget {
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

    const GCashPaymentScreen({
      super.key,
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
    });

    @override
    State<GCashPaymentScreen> createState() => _GCashPaymentScreenState();
  }

  class _GCashPaymentScreenState extends State<GCashPaymentScreen> {
    final TextEditingController gcashNumberController = TextEditingController();
    final TextEditingController referenceNumberController = TextEditingController();
    bool isProcessing = false;
    bool hasAgreedToTerms = false;

    // Your static GCash QR code URL
    // Replace this with your actual QR code image URL from your server
    final String gcashQRCodeUrl = "assets/gcash.jpg";
    
    // Or use a base64 encoded QR code if you prefer
    // final String gcashQRCodeBase64 = "data:image/png;base64,iVBORw0KG...";

    @override
    void dispose() {
      gcashNumberController.dispose();
      referenceNumberController.dispose();
      super.dispose();
    }

    String _formatCurrency(double amount) {
      return NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2).format(amount);
    }

    void _copyToClipboard(String text, String label) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }

    void _showQRDialog() {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scan to Pay',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Image.network(
                    gcashQRCodeUrl,
                    height: 280,
                    width: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 280,
                        width: 280,
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'QR Code not available',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 280,
                        width: 280,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Open GCash app, tap "Scan QR", and scan this code to pay',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Amount: ${_formatCurrency(widget.totalAmount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> _submitPayment() async {
    if (!_validateForm()) return;

    setState(() => isProcessing = true);

    final url = Uri.parse("http://192.168.1.11/carGOAdmin/api/create_booking.php");

    try {
      final response = await http.post(url, body: {
        "car_id": widget.carId.toString(),
        "owner_id": widget.ownerId,
        "user_id": widget.userId,
        "full_name": widget.fullName,
        "email": widget.email,
        "contact": widget.contact,
        "pickup_date": widget.pickupDate,
        "return_date": widget.returnDate,
        "pickup_time": widget.pickupTime,
        "return_time": widget.returnTime,
        "rental_period": widget.rentalPeriod,
        "needs_delivery": widget.needsDelivery ? "1" : "0",
        "total_amount": widget.totalAmount.toStringAsFixed(2),
        "payment_method": "gcash",
        "gcash_number": gcashNumberController.text.trim(),
        "gcash_reference": referenceNumberController.text.trim(),
      });

      setState(() => isProcessing = false);

      // Debug: Print raw response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        _showError("Server error (${response.statusCode})");
        return;
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('JSON decode error: $e');
        _showError("Invalid server response. Please check server logs.\n\nResponse: ${response.body.substring(0, 100)}");
        return;
      }

      if (data["success"] == true) {
        _showSuccessDialog();
      } else {
        _showError(data["message"] ?? "Payment failed");
      }
    } catch (e) {
      setState(() => isProcessing = false);
      print('Exception: $e');
      _showError("Network error: $e");
    }
  }
    bool _validateForm() {
      if (gcashNumberController.text.trim().isEmpty) {
        _showError('Please enter your GCash number');
        return false;
      }
      
      String gcashNum = gcashNumberController.text.trim();
      if (!RegExp(r'^09\d{9}$').hasMatch(gcashNum)) {
        _showError('Please enter a valid GCash number (09XXXXXXXXX)');
        return false;
      }

      if (referenceNumberController.text.trim().isEmpty) {
        _showError('Please enter the reference number');
        return false;
      }

      if (!hasAgreedToTerms) {
        _showError('Please agree to the terms and conditions');
        return false;
      }

      return true;
    }

    void _showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    void _showSuccessDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
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
              SizedBox(height: 24),
              Text(
                'Payment Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your payment is being verified. You will receive a confirmation email once approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 14),
                minimumSize: Size(double.infinity, 0),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
            icon: Icon(Icons.arrow_back, color: Colors.black),
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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountCard(),
                    SizedBox(height: 24),
                    _buildShowQRButton(),
                    SizedBox(height: 24),
                    _buildInstructions(),
                    SizedBox(height: 24),
                    _buildGCashAccountDetails(),
                    SizedBox(height: 24),
                    Text(
                      'Payment Details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: gcashNumberController,
                      label: 'Your GCash Number',
                      hint: '09XX XXX XXXX',
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: referenceNumberController,
                      label: 'GCash Reference Number',
                      hint: 'Enter the 13-digit reference number',
                      icon: Icons.receipt_long,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20),
                    _buildTermsCheckbox(),
                    SizedBox(height: 24),
                    _buildBookingSummary(),
                    SizedBox(height: 100),
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
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showQRDialog,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, color: Colors.white, size: 32),
                  SizedBox(width: 12),
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
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007DFF), Color(0xFF0052CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF007DFF).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/5/5c/GCash_logo.png',
                    height: 24,
                    errorBuilder: (_, __, ___) => Icon(Icons.payment, color: Color(0xFF007DFF)),
                  ),
                ),
                Spacer(),
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
            SizedBox(height: 16),
            Text(
              _formatCurrency(widget.totalAmount),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 4),
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
        padding: EdgeInsets.all(16),
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
                SizedBox(width: 8),
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
            SizedBox(height: 12),
            _buildInstructionStep('1', 'Tap "View QR Code" button above'),
            _buildInstructionStep('2', 'Open GCash app and tap "Scan QR"'),
            _buildInstructionStep('3', 'Scan the QR code displayed'),
            _buildInstructionStep('4', 'Complete payment in GCash app'),
            _buildInstructionStep('5', 'Enter your details and reference number below'),
          ],
        ),
      );
    }

    Widget _buildInstructionStep(String number, String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
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
            SizedBox(width: 10),
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
        padding: EdgeInsets.all(16),
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
            SizedBox(height: 12),
            _buildCopyableField('Account Name', gcashName),
            SizedBox(height: 12),
            _buildCopyableField('GCash Number', gcashNumber),
            SizedBox(height: 12),
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
                SizedBox(height: 2),
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
            icon: Icon(Icons.copy, size: 18),
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
          SizedBox(height: 8),
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
                borderSide: BorderSide(color: Colors.black, width: 1.5),
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
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'I confirm that I have sent the payment and agree to the terms and conditions',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
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
        padding: EdgeInsets.all(16),
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
            SizedBox(height: 12),
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
        padding: EdgeInsets.only(bottom: 8),
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
            Expanded(
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
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, -5),
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
                : [Color(0xFF1a73e8), Color(0xFF0d47a1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isProcessing || !hasAgreedToTerms)
                  ? Colors.grey.withOpacity(0.3)
                  : Color(0xFF1a73e8).withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isProcessing || !hasAgreedToTerms) ? null : _submitPayment,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
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
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
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