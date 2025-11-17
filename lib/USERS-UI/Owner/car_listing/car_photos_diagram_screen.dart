import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/USERS-UI/Owner/models/car_listing.dart';
import 'package:flutter_application_1/USERS-UI/Owner/models/submit_car_api.dart'; // <-- Create this file (below)

class CarPhotosDiagramScreen extends StatefulWidget {
  final CarListing listing;

  const CarPhotosDiagramScreen({super.key, required this.listing});

  @override
  State<CarPhotosDiagramScreen> createState() => _CarPhotosDiagramScreenState();
}

class _CarPhotosDiagramScreenState extends State<CarPhotosDiagramScreen> {
  List<String> capturedPhotos = [];
  File? mainCarPhoto;

  @override
  Widget build(BuildContext context) {
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
          "Take Car Photos",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black),
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
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  _buildUploadTile("Upload Main Car Photo", isMain: true),

                  const SizedBox(height: 20),

                  Text("Additional Required Photos:", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),

                  ...List.generate(5, (i) => _buildUploadTile("Photo Spot ${i + 1}", index: i)),
                ],
              ),
            ),

            // ---- Submit Button ----
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _submitListing : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "Finish & Publish",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _canSubmit() ? const Color(0xFFCDFE3D) : Colors.grey[500],
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
    String? imagePath;

    if (isMain && mainCarPhoto != null) {
      imagePath = mainCarPhoto!.path;
    } else if (index != null && index < capturedPhotos.length) {
      imagePath = capturedPhotos[index];
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
        child: imagePath == null
            ? Center(child: Text(label, style: GoogleFonts.poppins(color: Colors.black54)))
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(imagePath), width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Future<void> _pickPhoto(bool isMain, int? index) async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (img == null) return;

    setState(() {
      if (isMain) {
        mainCarPhoto = File(img.path);
      } else {
        if (index! < capturedPhotos.length) {
          capturedPhotos[index] = img.path;
        } else {
          capturedPhotos.add(img.path);
        }
      }
    });
  }

  Future<void> _submitListing() async {
    // Attach photos to listing
    widget.listing.photoUrls = capturedPhotos;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await submitCarListing(
      listing: widget.listing,
      mainPhoto: mainCarPhoto,
      orFile: widget.listing.officialReceipt != null ? File(widget.listing.officialReceipt!) : null,
      crFile: widget.listing.certificateOfRegistration != null ? File(widget.listing.certificateOfRegistration!) : null,
      extraPhotos: capturedPhotos.map((e) => File(e)).toList(),
    );

    Navigator.pop(context); // close loader

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Car uploaded successfully 🎉")),
      );

      Navigator.pop(context, true); // return to MyCarPage to refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload. Try again.")),
      );
    }
  }
}
