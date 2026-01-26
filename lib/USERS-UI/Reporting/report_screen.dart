import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


// Configuration class for API
class ApiConfig {
  static const String baseUrl = "http://10.244.29.49/carGOAdmin/";
  static const Duration timeoutDuration = Duration(seconds: 30);
}

class ReportScreen extends StatefulWidget {
  final String reportType; // 'car', 'motorcycle', 'user', 'booking', 'chat'
  final String reportedId;
  final String reportedName;
  final String? reportedItemDetails; // Optional: Additional context
  
  const ReportScreen({
    super.key,
    required this.reportType,
    required this.reportedId,
    required this.reportedName,
    this.reportedItemDetails,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}
bool isSubmitting = false;
File? _selectedImage;
final ImagePicker _picker = ImagePicker();

class _ReportScreenState extends State<ReportScreen> {
  String? selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // Enhanced report reasons with better organization
  static const Map<String, List<ReportReason>> reportReasons = {
    'car': [
      ReportReason('Misleading information', Icons.error_outline),
      ReportReason('Fake photos', Icons.image_not_supported),
      ReportReason('Vehicle not as described', Icons.directions_car),
      ReportReason('Safety concerns', Icons.warning),
      ReportReason('Suspicious pricing', Icons.attach_money),
      ReportReason('Unavailable vehicle', Icons.block),
      ReportReason('Other', Icons.more_horiz),
    ],
    'motorcycle': [
      ReportReason('Misleading information', Icons.error_outline),
      ReportReason('Fake photos', Icons.image_not_supported),
      ReportReason('Vehicle not as described', Icons.two_wheeler),
      ReportReason('Safety concerns', Icons.warning),
      ReportReason('Suspicious pricing', Icons.attach_money),
      ReportReason('Unavailable vehicle', Icons.block),
      ReportReason('Other', Icons.more_horiz),
    ],
    'user': [
      ReportReason('Inappropriate behavior', Icons.person_off),
      ReportReason('Harassment', Icons.report_problem),
      ReportReason('Fraud/Scam', Icons.gavel),
      ReportReason('Fake profile', Icons.account_circle),
      ReportReason('Suspicious activity', Icons.security),
      ReportReason('Spam', Icons.warning_amber),
      ReportReason('Other', Icons.more_horiz),
    ],
    'booking': [
      ReportReason('No-show', Icons.event_busy),
      ReportReason('Late pickup/return', Icons.schedule),
      ReportReason('Vehicle damage', Icons.car_crash),
      ReportReason('Cleanliness issues', Icons.cleaning_services),
      ReportReason('Payment dispute', Icons.payment),
      ReportReason('Cancellation issues', Icons.cancel),
      ReportReason('Other', Icons.more_horiz),
    ],
    'chat': [
      ReportReason('Harassment', Icons.report_problem),
      ReportReason('Spam messages', Icons.warning_amber),
      ReportReason('Inappropriate content', Icons.block),
      ReportReason('Scam attempt', Icons.gavel),
      ReportReason('Threatening behavior', Icons.warning),
      ReportReason('Other', Icons.more_horiz),
    ],
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

Future<void> _pickImage() async {
  final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 70, // compress
  );

  if (pickedFile != null) {
    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }
}


  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null || userId.isEmpty) {
      throw Exception("User not logged in");
    }
    return userId;
  }

  Future<void> _submitReport() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedReason == null) {
      _showSnackBar('Please select a reason', isError: true);
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => isSubmitting = true);

    try {
      final userId = await _getUserId();
      final url = Uri.parse("${ApiConfig.baseUrl}api/submit_report.php");
      
      final request = http.MultipartRequest('POST', url);

request.fields['report_type'] = widget.reportType.toLowerCase().trim();
request.fields['reported_id'] = widget.reportedId;
request.fields['reason'] = selectedReason!;
request.fields['details'] = _detailsController.text.trim();
request.fields['reporter_id'] = userId;

// Optional image
if (_selectedImage != null) {
  request.files.add(
    await http.MultipartFile.fromPath(
      'image', // MUST match PHP: $_FILES['image']
      _selectedImage!.path,
    ),
  );
}

final streamedResponse = await request.send().timeout(
  ApiConfig.timeoutDuration,
  onTimeout: () {
    throw Exception("Request timed out. Please check your connection.");
  },
);

final response = await http.Response.fromStream(streamedResponse);
final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          if (mounted) {
            _showSuccessDialog();
          }
        } else {
          throw Exception(result['message'] ?? 'Failed to submit report');
        }
      } else {
        throw Exception("Server error (${response.statusCode}). Please try again later.");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to submit this report? False reports may result in account suspension.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Report Submitted',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for your report. Our team will review it within 24-48 hours.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close report screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Done', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reasons = reportReasons[widget.reportType.toLowerCase().trim()] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report ${_getTypeLabel()}',
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,



            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Help us understand the issue. Your report will be reviewed within 24-48 hours.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Reporting
                Text(
                  'You are reporting:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(), color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reportedName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).iconTheme.color,



                              ),
                            ),
                            if (widget.reportedItemDetails != null)
                              Text(
                                widget.reportedItemDetails!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Reason Selection
                Text(
                  'Select a reason *',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).iconTheme.color,



                  ),
                ),
                const SizedBox(height: 16),

                ...reasons.map((reason) => _buildReasonOption(reason)).toList(),

                const SizedBox(height: 32),

                // Details
                Text(
                  'Provide details *',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).iconTheme.color,



                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please describe the issue in detail (minimum 20 characters)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: _detailsController,
                    maxLines: 6,
                    maxLength: 500,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide details';
                      }
                      if (value.trim().length < 20) {
                        return 'Please provide at least 20 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Describe what happened in detail...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      errorStyle: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 32),

                // Optional Image Upload
Text(
  'Attach Image (Optional)',
  style: GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).iconTheme.color,



  ),
),
const SizedBox(height: 8),

GestureDetector(
  onTap: _pickImage,
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      children: [
        Icon(Icons.image, color: Colors.grey.shade600, size: 32),
        const SizedBox(height: 8),
        Text(
          _selectedImage == null
              ? 'Tap to select an image'
              : 'Image selected',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    ),
  ),
),

if (_selectedImage != null) ...[
  const SizedBox(height: 12),
  ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.file(
      _selectedImage!,
      height: 150,
      fit: BoxFit.cover,
      width: double.infinity,
    ),
  ),
],

const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.red.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Submit Report',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Disclaimer
                Center(
                  child: Text(
                    'False reports may result in account suspension',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonOption(ReportReason reason) {
    final isSelected = selectedReason == reason.text;

    return GestureDetector(
      onTap: () => setState(() => selectedReason = reason.text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              reason.icon,
              color: isSelected ? Colors.red : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.grey.shade700,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? Colors.red : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.reportType.toLowerCase()) {
      case 'car':
        return 'Car';
      case 'motorcycle':
        return 'Motorcycle';
      case 'user':
        return 'User';
      case 'booking':
        return 'Booking';
      case 'chat':
        return 'Conversation';
      default:
        return 'Issue';
    }
  }

  IconData _getTypeIcon() {
    switch (widget.reportType.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'user':
        return Icons.person;
      case 'booking':
        return Icons.event_note;
      case 'chat':
        return Icons.chat_bubble;
      default:
        return Icons.report;
    }
  }
}

// Helper class for report reasons
class ReportReason {
  final String text;
  final IconData icon;

  const ReportReason(this.text, this.icon);
}