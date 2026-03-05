import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ADD THIS
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cargo/USERS-UI/Owner/models/car_listing.dart';

class CarPhotoCaptureScreen extends StatefulWidget {
  final String photoLabel;
  final int spotNumber;
  final CarListing listing;

  const CarPhotoCaptureScreen({
    super.key,
    required this.photoLabel,
    required this.spotNumber,
    required this.listing,
  });

  @override
  State<CarPhotoCaptureScreen> createState() => _CarPhotoCaptureScreenState();
}

class _CarPhotoCaptureScreenState extends State<CarPhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  String? capturedImagePath;

  @override
  void initState() {
    super.initState();

    /// Restore the saved photo if user goes back
    if (widget.listing.carPhotos.containsKey(widget.spotNumber)) {
      capturedImagePath = widget.listing.carPhotos[widget.spotNumber];
    }

    // ✅ Android: recover image if the OS killed/recreated the Activity while the camera was open.
    // This prevents the flow from looking like it "crashed and restarted".
    _recoverLostImage();
    
    // ✅ Save current route to prevent navigation loss
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveCurrentRoute();
    });
  }
  
  Future<void> _saveCurrentRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_car_listing_route', 'photo_capture_screen');
      await prefs.setInt('pending_photo_spot_number', widget.spotNumber);
      debugPrint('✅ Saved current route: photo_capture_screen (spot ${widget.spotNumber})');
    } catch (e) {
      debugPrint('⚠️ Could not save route: $e');
    }
  }
  
  @override
  void dispose() {
    // Clear saved route when leaving normally
    _clearSavedRoute();
    super.dispose();
  }
  
  Future<void> _clearSavedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_car_listing_route');
      await prefs.remove('pending_photo_spot_number');
    } catch (e) {
      debugPrint('⚠️ Could not clear route: $e');
    }
  }

  Future<void> _recoverLostImage() async {
    // ✅ Skip on web
    if (kIsWeb) return;
    
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      final XFile? file = response.file;
      if (!mounted || file == null) return;

      setState(() {
        capturedImagePath = file.path;
      });
    } catch (e) {
      print("⚠️ Could not recover lost image: $e");
      // Ignore: recovery is best-effort.
    }
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
          widget.photoLabel,
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,



            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: capturedImagePath == null
                    ? _buildCameraButton()
                    : _buildPreviewImage(),
              ),
            ),

            if (capturedImagePath != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmImage,
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Theme.of(context).iconTheme.color,




                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() => capturedImagePath = null);
                      },
                      child: Text(
                        'Retake photo',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).iconTheme.color,



                          fontSize: 14,
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

  void _confirmImage() {
    // Save image into model before leaving screen
    widget.listing.carPhotos[widget.spotNumber] = capturedImagePath!;
    Navigator.pop(context, capturedImagePath);
  }

  Widget _buildCameraButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).iconTheme.color,



                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to take photo',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb // FIXED: Added platform check
            ? Image.network(
                capturedImagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  );
                },
              )
            : Image.file(
                File(capturedImagePath!),
                fit: BoxFit.cover,
                // ✅ CRITICAL FIX: Reduced from 1080 to 800 to save memory
                cacheWidth: 800,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  );
                },
              ),
      ),
    );
  }

  void _showImageSourceDialog() {
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
              'Choose Source',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('Gallery', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Camera', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // ✅ CRITICAL FIX: Use lower quality and resolution to prevent Android from killing the app
      final XFile? image = source == ImageSource.camera 
          ? await _picker.pickImage(
              source: source,
              imageQuality: 60, // ✅ Reduced from 70 to 60
              maxWidth: 1600,   // ✅ Reduced from 1920 to 1600
              maxHeight: 1200,  // ✅ Reduced from 1080 to 1200
              preferredCameraDevice: CameraDevice.rear,
            )
          : await _picker.pickImage(
              source: source,
              imageQuality: 60,
              maxWidth: 1600,
              maxHeight: 1200,
            );

      // ✅ CRITICAL: Check if widget is still mounted after camera/gallery closes
      if (!mounted) {
        print("⚠️ Widget disposed while picking image - app was likely killed by OS");
        return;
      }

      // ✅ CRITICAL: Check if user cancelled
      if (image == null) {
        print("📷 User cancelled photo selection");
        return;
      }

      // ✅ Check file size for safety
      final fileSize = await image.length();
      print("📸 Image size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB");

      // ✅ CRITICAL: Double-check mounted before setState
      if (!mounted) {
        print("⚠️ Widget disposed after image selection");
        return;
      }

      setState(() {
        capturedImagePath = image.path;
      });
      
      print("✅ Photo captured successfully: ${image.path}");
      
      // ✅ Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo captured successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("❌ Error picking image: $e");
      print("Stack trace: $stackTrace");
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}