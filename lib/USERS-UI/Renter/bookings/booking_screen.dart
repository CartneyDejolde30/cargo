import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final int carId;
  final String carName;
  final String carImage;
  final String pricePerDay;
  final String location;
  
  // User info for auto-fill
  final String? userId;
  final String? userFullName;
  final String? userEmail;
  final String? userMunicipality;

  const BookingScreen({
    super.key,
    required this.carId,
    required this.carName,
    required this.carImage,
    required this.pricePerDay,
    required this.location,
    this.userId,
    this.userFullName,
    this.userEmail,
    this.userMunicipality,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int currentStep = 0;
  bool bookWithDriver = false;
  String selectedGender = 'Male';
  String selectedPeriod = 'Day';

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  // Dates
  DateTime? pickupDate;
  DateTime? returnDate;
  TimeOfDay pickupTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay returnTime = TimeOfDay(hour: 17, minute: 0);

  double get basePrice => double.tryParse(widget.pricePerDay) ?? 0;
  double driverFee = 500; // Per day driver fee

  int get numberOfDays {
    if (pickupDate == null || returnDate == null) return 1;
    return returnDate!.difference(pickupDate!).inDays + 1;
  }

  double get totalAmount {
    double total = basePrice * numberOfDays;
    if (bookWithDriver) {
      total += driverFee * numberOfDays;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    // Auto-fill user data from profile
    if (widget.userFullName != null && widget.userFullName!.isNotEmpty) {
      fullNameController.text = widget.userFullName!;
    }
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      emailController.text = widget.userEmail!;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          pickupDate = picked;
          if (returnDate == null || returnDate!.isBefore(picked)) {
            returnDate = picked.add(Duration(days: 1));
          }
        } else {
          returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isPickup ? pickupTime : returnTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          pickupTime = picked;
        } else {
          returnTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDriverToggle(),
                  SizedBox(height: 24),

                  // User Information Section
                  _buildTextField(
                    controller: fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    hint: 'Enter your full name',
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    controller: emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    controller: contactController,
                    label: 'Contact Number',
                    icon: Icons.phone_outlined,
                    hint: 'e.g., 09XX XXX XXXX',
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 24),

                  // Gender Selection
                  Text(
                    'Gender',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildGenderSelection(),
                  SizedBox(height: 24),

                  // Rental Period
                  Text(
                    'Rental Date & Time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildPeriodSelector(),
                  SizedBox(height: 20),

                  // Date Pickers
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Pick up Date',
                          date: pickupDate,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Return Date',
                          date: returnDate,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          label: 'Pick up Time',
                          time: pickupTime,
                          onTap: () => _selectTime(context, true),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTimePicker(
                          label: 'Return Time',
                          time: returnTime,
                          onTap: () => _selectTime(context, false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Car Location
                  Text(
                    'Car Location',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildLocationDisplay(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Booking details'),
          Expanded(child: _buildConnector(0)),
          _buildStepIndicator(1, 'Payment methods'),
          Expanded(child: _buildConnector(1)),
          _buildStepIndicator(2, 'confirmation'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.white,
            border: Border.all(
              color: isActive ? Colors.black : Colors.grey.shade300,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? Icon(Icons.check, color: Colors.white, size: 16)
                : Container(),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int step) {
    bool isActive = currentStep > step;
    return Container(
      height: 2,
      margin: EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.black : Colors.grey.shade300,
    );
  }

  Widget _buildDriverToggle() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book with driver',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Don\'t have a driver book with driver',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: bookWithDriver,
            onChanged: (value) {
              setState(() {
                bookWithDriver = value;
              });
            },
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Row(
      children: [
        _buildGenderOption('Male', Icons.male),
        SizedBox(width: 12),
        _buildGenderOption('Female', Icons.female),
        SizedBox(width: 12),
        _buildGenderOption('Others', Icons.transgender),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    bool isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedGender = gender;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                gender,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodOption('Day'),
        SizedBox(width: 12),
        _buildPeriodOption('Weekly'),
        SizedBox(width: 12),
        _buildPeriodOption('Monthly'),
      ],
    );
  }

  Widget _buildPeriodOption(String period) {
    bool isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = period;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd January yyyy').format(date)
                        : 'Select date',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: date != null ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDisplay() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.location,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () {
            if (_validateForm()) {
              _proceedToPayment();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₱${totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '  •  ',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Text(
                'Pay Now',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    if (fullNameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return false;
    }
    if (contactController.text.trim().isEmpty) {
      _showError('Please enter your contact number');
      return false;
    }
    if (pickupDate == null) {
      _showError('Please select pickup date');
      return false;
    }
    if (returnDate == null) {
      _showError('Please select return date');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _proceedToPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Booking Summary',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Car: ${widget.carName}', style: GoogleFonts.poppins()),
            Text('Days: $numberOfDays', style: GoogleFonts.poppins()),
            Text('With Driver: ${bookWithDriver ? "Yes (+₱${driverFee * numberOfDays})" : "No"}',
                style: GoogleFonts.poppins()),
            Divider(),
            Text(
              'Total: ₱${totalAmount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Process payment and create booking
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    super.dispose();
  }
}