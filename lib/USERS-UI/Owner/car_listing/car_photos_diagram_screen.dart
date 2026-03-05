import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cargo/USERS-UI/Owner/models/car_listing.dart';
import 'package:cargo/USERS-UI/Owner/models/submit_car_api.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CarPhotosDiagramScreen extends StatefulWidget {
  final CarListing listing;
  final String vehicleType;

  const CarPhotosDiagramScreen({
    super.key,
    required this.listing,
    this.vehicleType = 'car',
  });

  @override
  State<CarPhotosDiagramScreen> createState() => _CarPhotosDiagramScreenState();
}

class _CarPhotosDiagramScreenState extends State<CarPhotosDiagramScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> capturedPhotos = [];
  File? mainCarPhoto;
  bool _isSubmitting = false; // ✅ Prevent double submissions

  @override
  void initState() {
    super.initState();
    _recoverLostPhoto();
  }

  Future<void> _recoverLostPhoto() async {
    // ✅ Skip on web
    if (kIsWeb) return;
    
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      final XFile? file = response.file;
      if (!mounted || file == null) return;

      // Best-effort: if we don't know which slot was being captured, set as main photo.
      // This is still much better than losing the photo and restarting the flow.
      setState(() {
        mainCarPhoto = File(file.path);
      });
    } catch (e) {
      print("⚠️ Could not recover lost photo: $e");
      // Ignore: recovery is best-effort.
    }
  }

  @override
  void dispose() {
    // ✅ Clean up resources
    capturedPhotos.clear();
    mainCarPhoto = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMoto = widget.vehicleType == 'motorcycle';
    
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
          isMoto ? "Take Motorcycle Photos" : "Take Car Photos",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).iconTheme.color,



          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    "Capture clear photos of your vehicle",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildUploadTile(
                    isMoto ? "Upload Main Motorcycle Photo" : "Upload Main Car Photo", 
                    isMain: true
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Additional Required Photos:",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    5,
                    (i) => _buildUploadTile("Photo Spot ${i + 1}", index: i),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_canSubmit() && !_isSubmitting) ? _submitListing : null,
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).iconTheme.color,
                    disabledBackgroundColor: Colors.grey[400], // ✅ Show disabled state
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Finish & Publish",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: (_canSubmit() && !_isSubmitting) ? Colors.white : Colors.grey[500],
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

  bool _canSubmit() {
    return mainCarPhoto != null;
  }

  Widget _buildUploadTile(String label, {bool isMain = false, int? index}) {
    File? imageFile;

    if (isMain && mainCarPhoto != null) {
      imageFile = mainCarPhoto;
    } else if (index != null && index < capturedPhotos.length) {
      imageFile = capturedPhotos[index];
    }

    return GestureDetector(
      onTap: () => _pickPhoto(isMain, index),
      child: Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black26),
        ),
        child: imageFile == null
            ? Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: kIsWeb
                    ? Image.network(
                        imageFile.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
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
                        imageFile, 
                        fit: BoxFit.cover,
                        // ✅ CRITICAL FIX: Reduce memory usage by downsampling during decode
                        cacheWidth: 400, // Limit decoded width to 400px for thumbnails
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
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
      ),
    );
  }

  Future<void> _pickPhoto(bool isMain, int? index) async {
    try {
      // ✅ CRITICAL FIX: Use even lower quality and resolution to prevent Android from killing the app
      final XFile? img = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60, // ✅ Reduced from 70 to 60 to save more memory
        maxWidth: 1600,   // ✅ Reduced from 1920 to 1600
        maxHeight: 1200,  // ✅ Reduced from 1080 to 1200 (maintain 4:3 ratio)
        preferredCameraDevice: CameraDevice.rear, // ✅ Explicitly use rear camera
      );

      // ✅ CRITICAL: Check if widget is still mounted after camera closes
      if (!mounted) {
        print("⚠️ Widget disposed while capturing photo - app was likely killed by OS");
        return;
      }

      if (img == null) {
        print("📷 User cancelled photo capture");
        return;
      }

      // ✅ Check file size
      final fileSize = await img.length();
      print("📸 Image captured: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB");
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Image too large. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      File imageFile;
      if (kIsWeb) {
        // ✅ FIX: Web doesn't support File.fromRawPath
        // For web, we'll use the XFile path directly
        imageFile = File(img.path);
      } else {
        imageFile = File(img.path);
      }

      // ✅ CRITICAL: Double-check mounted before setState
      if (!mounted) {
        print("⚠️ Widget disposed after file conversion");
        return;
      }

      setState(() {
        if (isMain) {
          // ✅ Dispose old image if exists
          mainCarPhoto = imageFile;
          print("✅ Main photo set: ${imageFile.path}");
        } else {
          if (index != null) {
            if (index < capturedPhotos.length) {
              // ✅ Replace existing photo
              capturedPhotos[index] = imageFile;
              print("✅ Photo $index replaced: ${imageFile.path}");
            } else {
              // ✅ Add new photo
              capturedPhotos.add(imageFile);
              print("✅ Photo $index added: ${imageFile.path}");
            }
          }
        }
      });
      
      // ✅ Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Photo captured successfully"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("❌ Error picking photo: $e");
      print("Stack trace: $stackTrace");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to capture photo: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitListing() async {
    // ✅ Prevent double submissions
    if (_isSubmitting) {
      print("⚠️ Already submitting, ignoring duplicate request");
      return;
    }

    setState(() => _isSubmitting = true);

    final isMoto = widget.vehicleType == 'motorcycle';
    
    print("🚀 Starting vehicle upload...");
    print("📸 Main photo: ${mainCarPhoto != null ? 'Yes' : 'No'}");
    print("📸 Additional photos: ${capturedPhotos.length}");
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false, // ✅ Prevent back button during upload
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Uploading photos...\nPlease don't close the app",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Prepare document files
      File? orFile;
      File? crFile;

      if (widget.listing.officialReceipt != null) {
        if (kIsWeb) {
          print("⚠️ Web: OR file handling needs update");
        } else {
          orFile = File(widget.listing.officialReceipt!);
        }
      }

      if (widget.listing.certificateOfRegistration != null) {
        if (kIsWeb) {
          print("⚠️ Web: CR file handling needs update");
        } else {
          crFile = File(widget.listing.certificateOfRegistration!);
        }
      }

      // 🔧 FIX: Use submitVehicleListing with vehicleType parameter
      final success = await submitVehicleListing(
        listing: widget.listing,
        mainPhoto: mainCarPhoto,
        orFile: orFile,
        crFile: crFile,
        extraPhotos: capturedPhotos,
        vehicleType: widget.vehicleType, // ✅ CRITICAL: Pass vehicle type
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        print("✅ Upload successful!");
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMoto
                  ? "✅ Motorcycle uploaded successfully!"
                  : "✅ Car uploaded successfully!"
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // ✅ FIX: Pop all car listing screens (9 total) to return to MyCarPage
        // Flow: MyCarPage -> VehicleTypeSelection -> CarDetails -> CarPreferences 
        // -> CarFeatures -> CarRules -> CarPricing -> CarLocation 
        // -> UploadDocuments -> CarPhotosDiagram
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Pop all 9 screens in the listing flow to return to MyCarPage
        // The MyCarPage will auto-refresh and show the newly added vehicle
        int count = 0;
        Navigator.of(context).popUntil((route) {
          return count++ >= 9; // Pop all 9 car listing screens
        });
        
      } else {
        print("❌ Upload failed");
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to upload. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        setState(() => _isSubmitting = false); // ✅ Re-enable submission on failure
      }
    } catch (e, stackTrace) {
      print("❌ Exception during submission: $e");
      print("Stack trace: $stackTrace");
      
      if (!mounted) return;
      
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      setState(() => _isSubmitting = false); // ✅ Re-enable submission on error
    }
  }
}