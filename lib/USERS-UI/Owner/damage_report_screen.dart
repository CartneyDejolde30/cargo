import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cargo/config/api_config.dart';

class DamageReportScreen extends StatefulWidget {
  final int bookingId;
  final String ownerId;
  final String vehicleName;
  final String renterName;

  const DamageReportScreen({
    super.key,
    required this.bookingId,
    required this.ownerId,
    required this.vehicleName,
    required this.renterName,
  });

  @override
  State<DamageReportScreen> createState() => _DamageReportScreenState();
}

class _DamageReportScreenState extends State<DamageReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _costController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingExisting = true;
  Map<String, dynamic>? _existingReport;

  final List<String> _allDamageTypes = [
    'Scratches',
    'Dents',
    'Broken Glass',
    'Interior Damage',
    'Tire Damage',
    'Engine Damage',
    'Bumper Damage',
    'Mirror Damage',
    'Other',
  ];
  final Set<String> _selectedTypes = {};
  final List<XFile?> _images = [null, null, null, null];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkExistingReport();
  }

  @override
  void dispose() {
    _descController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReport() async {
    try {
      final uri = Uri.parse(
        '${GlobalApiConfig.getDamageReportEndpoint}?booking_id=${widget.bookingId}&owner_id=${widget.ownerId}',
      );
      final response = await http.get(uri).timeout(GlobalApiConfig.apiTimeout);
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _existingReport = data['report'];
          _isCheckingExisting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingExisting = false);
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _images[index] = picked);
    }
  }

  void _removeImage(int index) {
    setState(() => _images[index] = null);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      _showError('Please select at least one damage type.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(GlobalApiConfig.submitDamageReportEndpoint),
      );

      request.fields['booking_id'] = widget.bookingId.toString();
      request.fields['owner_id'] = widget.ownerId;
      request.fields['damage_types'] = json.encode(_selectedTypes.toList());
      request.fields['description'] = _descController.text.trim();
      request.fields['estimated_cost'] = _costController.text.trim();

      for (int i = 0; i < 4; i++) {
        if (_images[i] != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image_${i + 1}',
              _images[i]!.path,
            ),
          );
        }
      }

      final streamed = await request.send().timeout(GlobalApiConfig.uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      final data = json.decode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data['success'] == true) {
        _showSuccess('Damage report submitted successfully. Admin will review it shortly.');
        await _checkExistingReport();
      } else {
        _showError(data['message'] ?? 'Failed to submit report.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Network error. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('File Damage Report', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
      ),
      body: _isCheckingExisting
          ? const Center(child: CircularProgressIndicator())
          : _existingReport != null
              ? _buildExistingReport()
              : _buildForm(),
    );
  }

  Widget _buildExistingReport() {
    final report = _existingReport!;
    final status = report['status']?.toString() ?? 'pending';
    final types = _parseTypes(report['damage_types']);
    final images = [
      report['image_1'], report['image_2'], report['image_3'], report['image_4']
    ].where((e) => e != null && e.toString().isNotEmpty).toList();

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.cancel;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.hourglass_top;
        statusLabel = 'Pending Review';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (status == 'approved')
                        Text(
                          '₱${double.tryParse(report['approved_amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} deducted from security deposit',
                          style: GoogleFonts.inter(fontSize: 13, color: statusColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard('Damage Types', types.join(', ')),
          const SizedBox(height: 12),
          _buildInfoCard('Description', report['description'] ?? ''),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Estimated Cost',
            '₱${double.tryParse(report['estimated_cost']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
          ),
          if (report['admin_notes'] != null && report['admin_notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoCard('Admin Notes', report['admin_notes']),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Photos', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  GlobalApiConfig.getImageUrl(images[i].toString()),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<String> _parseTypes(dynamic raw) {
    if (raw == null) return [];
    try {
      if (raw is List) return List<String>.from(raw);
      final decoded = json.decode(raw.toString());
      if (decoded is List) return List<String>.from(decoded);
    } catch (_) {}
    return [];
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.car_crash, color: Colors.red.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vehicleName,
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Renter: ${widget.renterName}  •  Booking #BK-${widget.bookingId.toString().padLeft(4, '0')}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Damage types
            Text('Damage Types *', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Select all that apply',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allDamageTypes.map((type) {
                final selected = _selectedTypes.contains(type);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedTypes.remove(type);
                      } else {
                        _selectedTypes.add(type);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.red.shade700 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? Colors.red.shade700 : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description
            Text('Description *', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the damage in detail (min 10 characters)...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Description is required';
                if (v.trim().length < 10) return 'Minimum 10 characters required';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Estimated cost
            Text('Estimated Repair Cost *', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                hintText: '0.00',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Estimated cost is required';
                final amount = double.tryParse(v.trim());
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Photos
            Text('Damage Photos', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Upload up to 4 photos as evidence',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: 4,
              itemBuilder: (context, i) => _buildImageSlot(i),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _isLoading ? 'Submitting...' : 'Submit Damage Report',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin will review your report and notify both parties within 24–48 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    final file = _images[index];
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file != null ? Colors.red.shade300 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: file != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      File(file.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text(
                    'Photo ${index + 1}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
      ),
    );
  }
}
