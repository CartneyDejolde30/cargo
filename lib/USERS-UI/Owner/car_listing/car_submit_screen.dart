import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cargo/USERS-UI/Owner/models/car_listing.dart';
import 'package:cargo/USERS-UI/Owner/models/submit_car_api.dart';

class CarSubmitScreen extends StatefulWidget {
  final CarListing listing;
  final String vehicleType;

  const CarSubmitScreen({
    super.key,
    required this.listing,
    this.vehicleType = 'car',
  });

  @override
  State<CarSubmitScreen> createState() => _CarSubmitScreenState();
}

class _CarSubmitScreenState extends State<CarSubmitScreen> {
  bool isSubmitting = false;

  Future<void> _submit() async {
    setState(() => isSubmitting = true);

    // MAIN PHOTO
    File? mainPhoto = widget.listing.carPhotos.containsKey(1)
        ? File(widget.listing.carPhotos[1]!)
        : null;

    // DOCUMENTS
    File? orFile = widget.listing.officialReceipt != null
        ? File(widget.listing.officialReceipt!)
        : null;

    File? crFile = widget.listing.certificateOfRegistration != null
        ? File(widget.listing.certificateOfRegistration!)
        : null;

    // EXTRA PHOTOS
    List<File> extraPhotos = [];
    widget.listing.carPhotos.forEach((index, path) {
      if (index != 1) extraPhotos.add(File(path));
    });

    final success = await submitVehicleListing(
      listing: widget.listing,
      mainPhoto: mainPhoto,
      orFile: orFile,
      crFile: crFile,
      extraPhotos: extraPhotos,
      vehicleType: widget.vehicleType,
    );

    setState(() => isSubmitting = false);

    if (!mounted) return;

    if (success) {
      final isMoto = widget.vehicleType == 'motorcycle';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isMoto ? "🏍️ Motorcycle successfully submitted!" : "🚗 Car successfully submitted!"),
          backgroundColor: Theme.of(context).iconTheme.color,
        ),
      );

      // 🔥 Return to MyCars Screen and refresh
      Navigator.pop(context, true);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Upload failed. Try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMoto = widget.vehicleType == 'motorcycle';

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("Review & Submit")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📌 ${isMoto ? 'Motorcycle' : 'Car'}: ${widget.listing.brand} ${widget.listing.model}",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text("📍 Location: ${widget.listing.location}", style: GoogleFonts.poppins()),
                    const SizedBox(height: 10),
                    Text("💰 Rate: ₱${widget.listing.dailyRate}/day", style: GoogleFonts.poppins()),
                    const SizedBox(height: 10),
                    Text(
                      "📷 Total photos: ${widget.listing.carPhotos.length}",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).iconTheme.color,




                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Submit Vehicle",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
