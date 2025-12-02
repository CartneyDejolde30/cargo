import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:flutter_application_1/USERS-UI/Owner/models/user_verification.dart';
import 'package:flutter_application_1/USERS-UI/Owner/verification/selfie_screen.dart';

class IDUploadScreen extends StatefulWidget {
  final UserVerification verification;

  const IDUploadScreen({Key? key, required this.verification}) : super(key: key);

  @override
  State<IDUploadScreen> createState() => _IDUploadScreenState();
}

class _IDUploadScreenState extends State<IDUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _frontImage;
  File? _backImage;
  String? _selectedIdType;

  final List<Map<String, String>> idTypes = [
    {'value': 'drivers_license', 'label': 'Driver\'s License'},
    {'value': 'passport', 'label': 'Passport'},
    {'value': 'national_id', 'label': 'National ID'},
    {'value': 'umid', 'label': 'UMID'},
    {'value': 'sss', 'label': 'SSS ID'},
    {'value': 'philhealth', 'label': 'PhilHealth ID'},
    {'value': 'voters_id', 'label': 'Voter\'s ID'},
    {'value': 'postal_id', 'label': 'Postal ID'},
  ];

  @override
  void initState() {
    super.initState();

    // Restore previously entered data if user navigates back
    _selectedIdType = widget.verification.idType;
    
    if (widget.verification.idFrontPhoto != null) {
      _frontImage = File(widget.verification.idFrontPhoto!);
    }
    if (widget.verification.idBackPhoto != null) {
      _backImage = File(widget.verification.idBackPhoto!);
    }
  }

  // Camera Take
  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _frontImage = File(image.path);
            widget.verification.idFrontPhoto = image.path;
          } else {
            _backImage = File(image.path);
            widget.verification.idBackPhoto = image.path;
          }
        });
      }
    } catch (e) {
      _showError("Failed to capture image");
    }
  }

  // Pick from Gallery
  Future<void> _pickFromGallery(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _frontImage = File(image.path);
            widget.verification.idFrontPhoto = image.path;
          } else {
            _backImage = File(image.path);
            widget.verification.idBackPhoto = image.path;
          }
        });
      }
    } catch (e) {
      _showError("Failed to pick from gallery");
    }
  }

  // Bottom sheet selector
  void _showImageSourceOptions(bool isFront) {
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
            Text('Choose Image Source',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.black),
              title: Text('Camera', style: GoogleFonts.poppins(fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isFront);
              },
            ),

            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.black),
              title: Text('Gallery', style: GoogleFonts.poppins(fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(isFront);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _continue() {
    if (_selectedIdType == null) {
      _showError("Please select an ID type.");
      return;
    }

    if (_frontImage == null || _backImage == null) {
      _showError("Please upload front and back images of the ID.");
      return;
    }

    // Save selection to model
    widget.verification.idType = _selectedIdType;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelfieScreen(verification: widget.verification)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedIdType != null && _frontImage != null && _backImage != null;

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
          'Verification',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Progress status bar (unchanged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _buildProgressDot(true),
                  Expanded(child: _buildProgressLine(true)),
                  _buildProgressDot(true),
                  Expanded(child: _buildProgressLine(false)),
                  _buildProgressDot(false),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Valid ID',
                      style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    Text('Please upload a clear photo of your government-issued ID.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 24),

                    // Dropdown for ID selection
                    _buildDropdown(),

                    const SizedBox(height: 32),

                    _buildUploadSection('Front of ID', true),
                    const SizedBox(height: 24),

                    _buildUploadSection('Back of ID', false),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canContinue ? const Color(0xFFCDFE3D) : Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: canContinue ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- UI Helpers (No UI change) ----------

  Widget _buildProgressDot(bool active) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: active ? const Color(0xFFCDFE3D) : Colors.grey[300],
      shape: BoxShape.circle,
    ),
  );

  Widget _buildProgressLine(bool active) => Container(
    height: 2,
    color: active ? const Color(0xFFCDFE3D) : Colors.grey[300],
  );

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ID Type', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedIdType,
              isExpanded: true,
              hint: Text('Select ID Type', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
              items: idTypes.map((id) => DropdownMenuItem(
                value: id['value'],
                child: Text(id['label']!, style: GoogleFonts.poppins(fontSize: 13)),
              )).toList(),

              onChanged: (value) {
                setState(() {
                  _selectedIdType = value;
                  widget.verification.idType = value; // store to model
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection(String title, bool isFront) {
    final image = isFront ? _frontImage : _backImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => _showImageSourceOptions(isFront),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image != null ? const Color(0xFFCDFE3D) : Colors.grey[300]!,
                width: 2,
              ),
            ),

            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(image, width: double.infinity, fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text('Tap to upload', style: GoogleFonts.poppins(fontSize: 14)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
