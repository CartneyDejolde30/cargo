import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cargo/USERS-UI/Owner/models/car_listing.dart';
import 'car_photos_diagram_screen.dart';

class UploadDocumentsScreen extends StatefulWidget {
  final CarListing listing;
  final String vehicleType;

  const UploadDocumentsScreen({
    super.key,
    required this.listing,
    this.vehicleType = 'car',
  });

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final ImagePicker _picker = ImagePicker();

  // CHANGED: Store File objects instead of just paths
  File? officialReceiptFile;
  File? certificateOfRegistrationFile;

  @override
  void initState() {
    super.initState();
    _recoverLostDocument();
    // Try to restore from paths if coming back (mobile only)
    if (!kIsWeb) {
      if (widget.listing.officialReceipt != null) {
        officialReceiptFile = File(widget.listing.officialReceipt!);
      }
      if (widget.listing.certificateOfRegistration != null) {
        certificateOfRegistrationFile = File(widget.listing.certificateOfRegistration!);
      }
    }
  }

  bool _canContinue() {
    return officialReceiptFile != null && certificateOfRegistrationFile != null;
  }

  // ✅ Android: recover image if the OS killed/recreated the Activity while the camera was open.
  Future<void> _recoverLostDocument() async {
    // ✅ Skip on web
    if (kIsWeb) return;
    
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      final XFile? file = response.file;
      if (!mounted || file == null) return;

      // We can't reliably know whether it was OR or CR; prefer filling the first missing slot.
      final recovered = File(file.path);
      setState(() {
        if (officialReceiptFile == null) {
          officialReceiptFile = recovered;
          widget.listing.officialReceipt = file.path;
        } else if (certificateOfRegistrationFile == null) {
          certificateOfRegistrationFile = recovered;
          widget.listing.certificateOfRegistration = file.path;
        }
      });
    } catch (e) {
      print("⚠️ Could not recover lost document: $e");
      // Ignore: recovery is best-effort.
    }
  }

  // ✅ NEW: Show bottom sheet to choose camera or gallery
  Future<void> _pickDocument(bool isOR) async {
    try {
      final ImageSource? source = await _showImageSourceBottomSheet();
      
      if (source == null) {
        print("📷 User cancelled source selection");
        return; // User cancelled
      }
      
      // ✅ CRITICAL FIX: Use lower quality and resolution to prevent Android from killing the app
      final XFile? image = source == ImageSource.camera
          ? await _picker.pickImage(
              source: source,
              imageQuality: 60, // ✅ Reduced from 85 to 60
              maxWidth: 1600,   // ✅ Reduced from 1920 to 1600
              maxHeight: 1600,  // ✅ Reduced from 1920 to 1600
              preferredCameraDevice: CameraDevice.rear,
            )
          : await _picker.pickImage(
              source: source,
              imageQuality: 60,
              maxWidth: 1600,
              maxHeight: 1600,
            );

      // ✅ CRITICAL: Check if widget is still mounted after camera/gallery closes
      if (!mounted) {
        print("⚠️ Widget disposed while picking document - app was likely killed by OS");
        return;
      }

      // ✅ CRITICAL: Check if user cancelled
      if (image == null) {
        print("📷 User cancelled document capture");
        return;
      }

      // ✅ Check file size
      final fileSize = await image.length();
      print("📸 Document size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB");

      // ✅ CRITICAL: Double-check mounted before setState
      if (!mounted) {
        print("⚠️ Widget disposed after document selection");
        return;
      }

      // FIXED: Properly convert XFile to File for both platforms
      // NOTE: This screen is primarily used on mobile. On Android/iOS, `image.path` is a real file path.
      // Some earlier implementations attempted `File.fromRawPath(bytes)` which is not a valid way to
      // represent a picked image and can crash.
      final File imageFile = File(image.path);

      setState(() {
        if (isOR) {
          officialReceiptFile = imageFile;
          widget.listing.officialReceipt = image.path; // Store path for reference
        } else {
          certificateOfRegistrationFile = imageFile;
          widget.listing.certificateOfRegistration = image.path;
        }
      });
    } catch (e, stackTrace) {
      print("❌ Document pick error: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW: Bottom sheet to select image source
  Future<ImageSource?> _showImageSourceBottomSheet() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Choose Image Source',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha :0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Camera',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Take a photo',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha :0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Choose from gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadBox(String label, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,



                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            file.path, // On web, File.path is a blob URL
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Image.file(
                            file,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            // ✅ CRITICAL FIX: Reduce memory usage by downsampling during decode
                            cacheWidth: 400, // Limit decoded width to 400px for thumbnails
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                      onPressed: () {
                        setState(() {
                          if (label == 'Official Receipt') {
                            officialReceiptFile = null;
                            widget.listing.officialReceipt = null;
                          } else {
                            certificateOfRegistrationFile = null;
                            widget.listing.certificateOfRegistration = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload OR/CR',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).iconTheme.color,



                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload clear copy of Official Receipt and Certificate of Registration',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Official Receipt',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUploadBox(
                      'Official Receipt',
                      officialReceiptFile,
                      () => _pickDocument(true),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Certificate of Registration',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUploadBox(
                      'Certificate of Registration',
                      certificateOfRegistrationFile,
                      () => _pickDocument(false),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue()
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarPhotosDiagramScreen(
                                listing: widget.listing,
                                vehicleType: widget.vehicleType,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).iconTheme.color,




                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      color: _canContinue() ? Colors.white : Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}