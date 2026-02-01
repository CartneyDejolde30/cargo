import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/overdue_service.dart';

class ExtensionRequestScreen extends StatefulWidget {
  final int bookingId;
  final String vehicleName;
  final DateTime originalReturnDate;
  final double dailyRate;

  const ExtensionRequestScreen({
    Key? key,
    required this.bookingId,
    required this.vehicleName,
    required this.originalReturnDate,
    required this.dailyRate,
  }) : super(key: key);

  @override
  State<ExtensionRequestScreen> createState() => _ExtensionRequestScreenState();
}

class _ExtensionRequestScreenState extends State<ExtensionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final OverdueService _overdueService = OverdueService();

  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _userId;

  int get _extensionDays {
    if (_selectedDate == null) return 0;
    return _selectedDate!.difference(widget.originalReturnDate).inDays;
  }

  double get _extensionFee {
    if (_extensionDays == 0) return 0;
    double baseFee = widget.dailyRate * _extensionDays;
    
    // Add 20% rush fee if less than 24 hours until return
    final hoursUntilReturn = widget.originalReturnDate.difference(DateTime.now()).inHours;
    if (hoursUntilReturn < 24) {
      baseFee *= 1.20; // +20% rush fee
    }
    
    return baseFee;
  }

  bool get _isRushRequest {
    final hoursUntilReturn = widget.originalReturnDate.difference(DateTime.now()).inHours;
    return hoursUntilReturn < 24;
  }

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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Request Extension',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                _buildInfoCard(),
                const SizedBox(height: 20),

                // Rush Warning
                if (_isRushRequest) _buildRushWarning(),
                if (_isRushRequest) const SizedBox(height: 20),

                // Date Selector
                _buildDateSelector(),
                const SizedBox(height: 20),

                // Fee Breakdown
                if (_selectedDate != null) _buildFeeBreakdown(),
                if (_selectedDate != null) const SizedBox(height: 20),

                // Reason Input
                _buildReasonInput(),
                const SizedBox(height: 30),

                // Submit Button
                _buildSubmitButton(),
              ],
            ),
          ),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Booking',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Vehicle', widget.vehicleName),
          _buildDetailRow('Booking ID', '#${widget.bookingId}'),
          _buildDetailRow(
            'Current Return Date',
            '${widget.originalReturnDate.month}/${widget.originalReturnDate.day}/${widget.originalReturnDate.year}',
          ),
          _buildDetailRow('Daily Rate', '₱${widget.dailyRate.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildRushWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rush Request',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                Text(
                  'Less than 24 hours until return. A 20% rush fee will be added.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select New Return Date',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Tap to select date'
                            : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: _selectedDate == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[700]),
                ],
              ),
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Extension: $_extensionDays day${_extensionDays > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown() {
    final baseFee = widget.dailyRate * _extensionDays;
    final rushFee = _isRushRequest ? baseFee * 0.20 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildFeeRow('Base Fee', baseFee, false),
          if (_isRushRequest) _buildFeeRow('Rush Fee (20%)', rushFee, false),
          const Divider(color: Colors.white24, height: 24),
          _buildFeeRow('Total Extension Fee', _extensionFee, true),
        ],
      ),
    );
  }

  Widget _buildReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason for Extension',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Please explain why you need more time...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a reason';
            }
            if (value.trim().length < 10) {
              return 'Please provide more detail (at least 10 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || _selectedDate == null) ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
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
            : Text(
                'Submit Request',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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

  Widget _buildFeeRow(String label, double amount, bool isTotal) {
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.originalReturnDate.add(const Duration(days: 1)),
      firstDate: widget.originalReturnDate.add(const Duration(days: 1)),
      lastDate: widget.originalReturnDate.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      _showErrorDialog('Please log in to request extension');
      return;
    }
    if (_selectedDate == null) {
      _showErrorDialog('Please select a new return date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _overdueService.requestExtension(
        bookingId: widget.bookingId,
        userId: int.parse(_userId!),
        requestedReturnDate: _selectedDate!,
        reason: _reasonController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to submit request');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error: $e');
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
            Text('Request Submitted', style: GoogleFonts.outfit()),
          ],
        ),
        content: Text(
          'Your extension request has been sent to the vehicle owner for approval. '
          'You will be notified once they respond.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
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
