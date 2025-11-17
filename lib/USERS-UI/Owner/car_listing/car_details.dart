import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/USERS-UI/Owner/models/car_listing.dart';
import 'car_preferences_screen.dart';
import 'package:http/http.dart' as http;

class CarDetailsScreen extends StatefulWidget {
  final CarListing? existingListing;
  final int ownerId;

  const CarDetailsScreen({
    super.key,
    this.existingListing,
    required this.ownerId,
  });

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  late CarListing listing;
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  bool _plateIsUnique = false;

  File? imageFile;
  Uint8List? webImage;

  final List<String> years = List.generate(10, (i) => (2025 - i).toString());
  final List<String> brands = ['Audi', 'BAIC', 'BMW', 'BYD', 'Changan', 'Changhe', 'Chery'];
  final Map<String, List<String>> modelsByBrand = {
    'Audi': ['A1', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8'],
    'BMW': ['1 Series', '2 Series', '3 Series', '4 Series', '5 Series'],
  };
  final List<String> bodyStyles = ['3-Door Hatchback', '5-Door Hatchback', 'Sedan', 'SUV'];

  @override
  void initState() {
    super.initState();

    listing = widget.existingListing ??
        CarListing(
          owner: widget.ownerId,
          carStatus: 'Available',
        );

    listing.photoUrls = List<String>.from(listing.photoUrls);

    listing.year ??= years[0];
    listing.brand ??= brands[0];
    listing.bodyStyle ??= bodyStyles[0];
    listing.trim ??= 'N/A';

    if (listing.brand != null) {
      final models = modelsByBrand[listing.brand!] ?? [];
      listing.model ??= models.isNotEmpty ? models[0] : null;
    }

    _plateController.text = listing.plateNumber ?? '';
    _colorController.text = listing.color ?? '';
    _plateIsUnique = _plateController.text.isNotEmpty;

    _plateController.addListener(() {
      setState(() {
        listing.plateNumber = _plateController.text;
        _plateIsUnique = _plateController.text.isNotEmpty;
      });
    });

    _colorController.addListener(() {
      setState(() {
        listing.color = _colorController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  bool _canContinue() {
    return listing.year != null &&
        listing.brand != null &&
        listing.model != null &&
        listing.bodyStyle != null &&
        listing.trim != null &&
        (listing.plateNumber?.isNotEmpty ?? false) &&
        (listing.color?.isNotEmpty ?? false);
  }

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
                      'What is your car?',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildDropdown('Year', years, listing.year, (value) {
                      setState(() => listing.year = value);
                    }),
                    const SizedBox(height: 20),
                    _buildDropdown('Car Brand', brands, listing.brand, (value) {
                      setState(() {
                        listing.brand = value;
                        final models = modelsByBrand[value] ?? [];
                        listing.model = models.isNotEmpty ? models[0] : null;
                      });
                    }),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      'Model',
                      listing.brand != null
                          ? (modelsByBrand[listing.brand!] ?? ['A1', 'A3', 'A4'])
                          : ['Select brand first'],
                      listing.model,
                      (value) => setState(() => listing.model = value),
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown('Body Style', bodyStyles, listing.bodyStyle, (value) {
                      setState(() => listing.bodyStyle = value);
                    }),
                    const SizedBox(height: 20),
                    _buildDropdown('Trim', ['N/A', 'Base', 'Sport', 'Luxury'], listing.trim, (value) {
                      setState(() => listing.trim = value);
                    }),
                    const SizedBox(height: 20),
                    _buildTextField('Plate Number', _plateController),
                    if (_plateIsUnique)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Plate number is unique.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildTextField('Car Color', _colorController),
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
                              builder: (context) => CarPreferencesScreen(listing: listing),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      color: _canContinue() ? const Color(0xFFCDFE3D) : Colors.grey[500],
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

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select $label', style: GoogleFonts.poppins(color: Colors.grey)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
