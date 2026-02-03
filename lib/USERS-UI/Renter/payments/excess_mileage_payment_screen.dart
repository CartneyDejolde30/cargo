import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ExcessMileagePaymentScreen extends StatefulWidget {
  final int bookingId;
  final String vehicleName;
  final int odometerStart;
  final int odometerEnd;
  final int actualMileage;
  final int allowedMileage;
  final int excessMileage;
  final double excessFee;
  final double rentalAmount;
  final bool isRentalPaid;

  const ExcessMileagePaymentScreen({
    super.key,
    required this.bookingId,
    required this.vehicleName,
    required this.odometerStart,
    required this.odometerEnd,
    required this.actualMileage,
    required this.allowedMileage,
    required this.excessMileage,
    required this.excessFee,
    required this.rentalAmount,
    required this.isRentalPaid,
  });

  @override
  State<ExcessMileagePaymentScreen> createState() => _ExcessMileagePaymentScreenState();
}

class _ExcessMileagePaymentScreenState extends State<ExcessMileagePaymentScreen> {
  final TextEditingController _gcashNumberController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  File? _proofImage;
  bool _isSubmitting = false;

  double get totalAmount {
    if (widget.isRentalPaid) {
      return widget.excessFee;
    } else {
      return widget.rentalAmount + widget.excessFee;
    }
  }

  Future<void> _selectProofImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Take Photo', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (photo != null) {
                  setState(() => _proofImage = File(photo.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (photo != null) {
                  setState(() => _proofImage = File(photo.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (_gcashNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter GCash number')),
      );
      return;
    }

    if (_referenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reference number')),
      );
      return;
    }

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload payment proof')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Use existing late fee payment API (can be adapted)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.218.197.49/carGOAdmin/api/payment/submit_late_fee_payment.php'),
      );

      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '0';
      
      request.fields['booking_id'] = widget.bookingId.toString();
      request.fields['user_id'] = userId;
      request.fields['late_fee_amount'] = widget.excessFee.toStringAsFixed(2);
      request.fields['rental_amount'] = widget.isRentalPaid ? '0.00' : widget.rentalAmount.toStringAsFixed(2);
      request.fields['total_amount'] = totalAmount.toStringAsFixed(2);
      request.fields['payment_method'] = 'gcash';
      request.fields['payment_reference'] = _referenceController.text;
      request.fields['gcash_number'] = _gcashNumberController.text;
      request.fields['is_rental_paid'] = widget.isRentalPaid ? '1' : '0';
      request.fields['payment_type'] = 'excess_mileage';

      request.files.add(
        await http.MultipartFile.fromPath('payment_proof', _proofImage!.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      setState(() => _isSubmitting = false);

      if (data['status'] == 'success') {
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text('Payment Submitted', style: GoogleFonts.poppins(fontSize: 18)),
              ],
            ),
            content: Text(
              'Your excess mileage payment has been submitted and is pending verification.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to submit payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Excess Mileage Payment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mileage Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Excess Mileage Detected',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.vehicleName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  _buildMileageRow('Starting Odometer:', '${widget.odometerStart} km'),
                  _buildMileageRow('Ending Odometer:', '${widget.odometerEnd} km'),
                  _buildMileageRow('Distance Driven:', '${widget.actualMileage} km', isBold: true),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  _buildMileageRow('Allowed Mileage:', '${widget.allowedMileage} km'),
                  _buildMileageRow('Excess Mileage:', '${widget.excessMileage} km', color: Colors.yellow.shade300, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                    'Payment Breakdown',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!widget.isRentalPaid) ...[
                    _buildPaymentRow('Rental Fee:', '₱${widget.rentalAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                  ],
                  _buildPaymentRow('Excess Mileage Fee:', '₱${widget.excessFee.toStringAsFixed(2)}', color: Colors.orange),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  _buildPaymentRow(
                    'Total Amount:',
                    '₱${totalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // GCash Payment Form
            Text(
              'GCash Payment Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // GCash Number
            TextField(
              controller: _gcashNumberController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'GCash Number',
                hintText: '09XXXXXXXXX',
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Reference Number
            TextField(
              controller: _referenceController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Reference Number',
                hintText: 'Enter GCash reference number',
                prefixIcon: const Icon(Icons.confirmation_number),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Payment Proof
            Text(
              'Payment Proof',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: _selectProofImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _proofImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Upload payment screenshot',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            if (_proofImage != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _selectProofImage,
                icon: const Icon(Icons.refresh),
                label: Text('Change Image', style: GoogleFonts.poppins()),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Payment - ₱${totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment will be verified by admin. You will receive a notification once verified.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
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

  Widget _buildMileageRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: color ?? Colors.white.withOpacity(0.9),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: color ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: color ?? (isTotal ? Theme.of(context).primaryColor : Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _gcashNumberController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
