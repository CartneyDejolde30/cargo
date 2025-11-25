import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/USERS-UI/Owner/models/user_verification.dart';
import 'package:flutter_application_1/USERS-UI/Owner/verification/id_upload_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final UserVerification? existingData;

  const PersonalInfoScreen({Key? key, this.existingData}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late UserVerification verification;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  final List<String> regions = [
    'NCR',
    'Region I',
    'Region II',
    'Region III',
    'Region IV-A',
    'Region V',
    'Region VI',
    'Region VII',
    'Region VIII (Caraga)'
  ];

  final List<String> genders = ['Male', 'Female'];

  Map<String, dynamic> caragaData = {};
  List<String> provinces = [];
  List<String> municipalities = [];
  List<String> barangays = [];

  @override
  void initState() {
    super.initState();
    verification = widget.existingData ?? UserVerification();
    _firstNameController.text = verification.firstName ?? '';
    _lastNameController.text = verification.lastName ?? '';
    _emailController.text = verification.email ?? '';
    _mobileController.text = verification.mobileNumber ?? '';

    _loadCaragaData();
  }

  Future<void> _loadCaragaData() async {
    final String response = await rootBundle.loadString('assets/data/caraga.json');
    final data = json.decode(response);

    setState(() {
      caragaData = data['Region VIII (Caraga)'] ?? {};
      provinces = caragaData.keys.toList();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _buildProgressDot(true),
                  Expanded(child: _buildProgressLine(false)),
                  _buildProgressDot(false),
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
                    Text('Personal Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildTextField('First Name', _firstNameController,
                        onChanged: (v) => verification.firstName = v),
                    const SizedBox(height: 16),

                    _buildTextField('Last Name', _lastNameController,
                        onChanged: (v) => verification.lastName = v),
                    const SizedBox(height: 24),

                    Text(
                      'PERMANENT ADDRESS',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Region
                    _buildDropdown('Region', regions, verification.permRegion,
                          (v) {
                        setState(() {
                          verification.permRegion = v;
                          if (v == 'Region VIII (Caraga)') {
                            provinces = caragaData.keys.toList();
                          }
                        });
                      }),

                    const SizedBox(height: 16),

                    // Province
                    if (verification.permRegion == 'Region VIII (Caraga)')
                      _buildDropdown('Province', provinces, verification.permProvince,
                              (v) {
                            setState(() {
                              verification.permProvince = v;
                              municipalities = caragaData[v]!.keys.toList();
                              verification.permCity = null;
                              barangays.clear();
                            });
                          }),

                    const SizedBox(height: 16),

                    // Municipality
                    if (municipalities.isNotEmpty)
                      _buildDropdown('Municipality', municipalities, verification.permCity,
                              (v) {
                            setState(() {
                              verification.permCity = v;
                              barangays = List<String>.from(caragaData[verification.permProvince][v]);
                              verification.permBarangay = null;
                            });
                          }),

                    const SizedBox(height: 16),

                    // Barangay
                    if (barangays.isNotEmpty)
                      _buildDropdown('Barangay', barangays, verification.permBarangay,
                              (v) => setState(() => verification.permBarangay = v)),

                    const SizedBox(height: 24),

                    _buildTextField('Email Address', _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => verification.email = v),

                    const SizedBox(height: 16),

                    _buildTextField('Mobile Number', _mobileController,
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => verification.mobileNumber = v),

                    const SizedBox(height: 16),

                    _buildDropdown('Gender', genders, verification.gender,
                        (v) => setState(() => verification.gender = v)),

                    const SizedBox(height: 16),

                    _buildDatePicker(),
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
                        builder: (context) => IDUploadScreen(verification: verification),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canContinue()
                        ? const Color(0xFFCDFE3D)
                        : Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _canContinue() ? Colors.black : Colors.grey[500],
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

  bool _canContinue() {
    return (verification.firstName?.isNotEmpty ?? false) &&
        (verification.lastName?.isNotEmpty ?? false) &&
        verification.permRegion != null &&
        verification.email != null &&
        verification.mobileNumber != null &&
        verification.gender != null &&
        verification.dateOfBirth != null;
  }

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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        )
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: verification.dateOfBirth ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => verification.dateOfBirth = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          verification.dateOfBirth != null
              ? DateFormat('yyyy-MM-dd').format(verification.dateOfBirth!)
              : 'Select Date',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }
}
