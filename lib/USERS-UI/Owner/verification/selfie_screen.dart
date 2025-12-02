import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_application_1/USERS-UI/Owner/models/user_verification.dart';

class SelfieScreen extends StatefulWidget {
  final UserVerification verification;

  const SelfieScreen({Key? key, required this.verification}) : super(key: key);

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selfieImage;
  Uint8List? _webImageBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Restore image if returning to screen
    if (widget.verification.selfiePhoto != null && !kIsWeb) {
      _selfieImage = File(widget.verification.selfiePhoto!);
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (kIsWeb) {
            image.readAsBytes().then((bytes) => _webImageBytes = bytes);
          } else {
            _selfieImage = File(image.path);
          }
          widget.verification.selfiePhoto = image.path;
        });
      }
    } catch (_) {
      _showError("Camera error. Try again.");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (kIsWeb) {
            image.readAsBytes().then((bytes) => _webImageBytes = bytes);
          } else {
            _selfieImage = File(image.path);
          }
          widget.verification.selfiePhoto = image.path;
        });
      }
    } catch (_) {
      _showError("Failed to access gallery.");
    }
  }

void _showImageSourceOptions() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose Image Source',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.black),
            title: Text('Take Photo',
                style: GoogleFonts.poppins(fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
              _takeSelfie();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.black),
            title: Text('Choose from Gallery',
                style: GoogleFonts.poppins(fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
              _pickFromGallery();
            },
          ),
        ],
      ),
    ),
  );
}


  bool _hasImage() => kIsWeb ? _webImageBytes != null : _selfieImage != null;

  Future<void> _submitVerification() async {
  if (!_hasImage()) {
    _showError("Please upload a selfie first.");
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    var url = Uri.parse("http://10.72.15.180/carGOAdmin/submit_verification.php");

    var request = http.MultipartRequest("POST", url);

    // Text fields
    request.fields['user_id'] = widget.verification.userId.toString();
    request.fields['first_name'] = widget.verification.firstName ?? "";
    request.fields['last_name'] = widget.verification.lastName ?? "";
    request.fields['email'] = widget.verification.email ?? "";
    request.fields['mobile'] = widget.verification.mobileNumber ?? "";
    request.fields['gender'] = widget.verification.gender ?? "";

    // Format DOB properly
    request.fields['dob'] = widget.verification.dateOfBirth != null
        ? widget.verification.dateOfBirth!.toIso8601String().substring(0, 10)
        : "";

    request.fields['region'] = widget.verification.permRegion ?? "";
    request.fields['province'] = widget.verification.permProvince ?? "";
    request.fields['municipality'] = widget.verification.permCity ?? "";
    request.fields['barangay'] = widget.verification.permBarangay ?? "";
    request.fields['id_type'] = widget.verification.idType ?? "";

    // Image files
    request.files.add(await http.MultipartFile.fromPath(
        "id_front_photo", widget.verification.idFrontPhoto!));

    request.files.add(await http.MultipartFile.fromPath(
        "id_back_photo", widget.verification.idBackPhoto!));

    request.files.add(await http.MultipartFile.fromPath(
        "selfie_photo", widget.verification.selfiePhoto!));

    var response = await request.send();
    var result = jsonDecode(await response.stream.bytesToString());

    if (result["success"] == true) {
      _showSuccessDialog();
    } else {
      _showError(result["message"] ?? "Something went wrong.");
    }

  } catch (e) {
    _showError("Request failed: $e");
  }

  if (mounted) setState(() => _isSubmitting = false);
}


  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
              child: Icon(Icons.check, size: 48, color: Colors.green[700]),
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Submitted!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your verification is under review.\nExpect an update within 24–48 hours.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCDFE3D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                      color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _hasImage() && !_isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verification',
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _progressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selfie with ID',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Take a selfie while holding your ID next to your face.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _selfiePreview(),
                    const SizedBox(height: 24),
                    _importantNotice(),
                  ],
                ),
              ),
            ),
            _submitButton(canSubmit),
          ],
        ),
      ),
    );
  }

  Widget _progressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _dot(true),
          _line(true),
          _dot(true),
          _line(true),
          _dot(true),
        ],
      ),
    );
  }

  Widget _dot(bool active) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFCDFE3D) : Colors.grey[300],
          shape: BoxShape.circle,
        ),
      );

  Widget _line(bool active) => Expanded(
        child: Container(
          height: 2,
          color: active ? const Color(0xFFCDFE3D) : Colors.grey[300],
        ),
      );

  Widget _selfiePreview() {
    final hasImage = _hasImage();

    return GestureDetector(
      onTap: _showImageSourceOptions,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
          border: Border.all(
              width: 2, color: hasImage ? const Color(0xFFCDFE3D) : Colors.grey[300]!),
        ),
        child: hasImage
            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: _imageWidget())
            : _placeholder(),
      ),
    );
  }

  Widget _imageWidget() {
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(_webImageBytes!,
          width: double.infinity, height: double.infinity, fit: BoxFit.cover);
    }
    if (!kIsWeb && _selfieImage != null) {
      return Image.file(_selfieImage!,
          width: double.infinity, height: double.infinity, fit: BoxFit.cover);
    }
    return const SizedBox();
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.badge_outlined, size: 80, color: Colors.grey[600]),
        const SizedBox(height: 24),
        Text('Tap to take photo',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          'Take selfie with ID or select one.',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _importantNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[100]!)),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
          SizedBox(width: 10),
          Expanded(
              child: Text(
            "Make sure your ID is clearly visible.",
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.red[800]),
          ))
        ],
      ),
    );
  }

  Widget _submitButton(bool canSubmit) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSubmit ? _submitVerification : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit ? const Color(0xFFCDFE3D) : Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
                )
              : Text(
                  "Submit Verification",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: canSubmit ? Colors.black : Colors.grey[500]),
                ),
        ),
      ),
    );
  }
}
