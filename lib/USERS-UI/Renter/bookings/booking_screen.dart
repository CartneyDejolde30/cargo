import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cargo/config/api_config.dart';
import '../bookings/pricing/pricing_calculator.dart';
import 'map_route_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gcash_payment_screen.dart';
import '../insurance/insurance_selection_screen.dart';
import '../../services/insurance_service.dart';
import '../widgets/renter_availability_calendar.dart';
import '../../../widgets/optimized_network_image.dart';

class BookingScreen extends StatefulWidget {
  final int carId;
  final String vehicleType;
  final String carName;
  final String carImage;
  final String pricePerDay;
  final String location;
  final String ownerId;
  final String? userId;
  final String? userFullName;
  final String? userEmail;
  final String? userContact;
  final String? userMunicipality;
  final double? ownerLatitude;
  final double? ownerLongitude;

  const BookingScreen({
    super.key,
    required this.vehicleType,
    required this.carId,
    required this.carName,
    required this.carImage,
    required this.pricePerDay,
    required this.ownerId,
    required this.location,
    this.userId,
    this.userFullName,
    this.userContact,
    this.userEmail,
    this.userMunicipality,
    this.ownerLatitude,
    this.ownerLongitude,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Verification states
  bool isCheckingVerification = true;
  bool isVerifiedUser = false;
  String? verificationError;
  String debugInfo = "Initializing...";

  int currentStep = 0;

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  // Dates
  DateTime? pickupDate;
  DateTime? returnDate;
  TimeOfDay pickupTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay returnTime = TimeOfDay(hour: 17, minute: 0);

  BookingPriceBreakdown? priceBreakdown;

  double get basePrice => double.tryParse(widget.pricePerDay) ?? 0;

  int get numberOfDays {
    if (pickupDate == null || returnDate == null) return 1;
    final pickup = DateTime(
      pickupDate!.year, pickupDate!.month, pickupDate!.day,
      pickupTime.hour, pickupTime.minute,
    );
    final returnDt = DateTime(
      returnDate!.year, returnDate!.month, returnDate!.day,
      returnTime.hour, returnTime.minute,
    );
    final totalMinutes = returnDt.difference(pickup).inMinutes;
    // Ceil to full 24-hour periods (min 1 day)
    return ((totalMinutes / (24 * 60)).ceil()).clamp(1, 9999);
  }

  /// Auto-detected rental period based on selected date range.
  String get rentalPeriod =>
      numberOfDays >= 30 ? 'Monthly' : numberOfDays >= 7 ? 'Weekly' : 'Day';

  /// True when pickup and return are on the same day and return time ≤ pickup time.
  bool get _isSameDayTimeInvalid {
    if (pickupDate == null || returnDate == null) return false;
    final sameDay = pickupDate!.year == returnDate!.year &&
        pickupDate!.month == returnDate!.month &&
        pickupDate!.day == returnDate!.day;
    if (!sameDay) return false;
    final pickupMinutes = pickupTime.hour * 60 + pickupTime.minute;
    final returnMinutes = returnTime.hour * 60 + returnTime.minute;
    return returnMinutes <= pickupMinutes;
  }

  // priceBreakdown.totalAmount already includes insurance (passed via insuranceFee param)
  double get totalWithInsurance => priceBreakdown?.totalAmount ?? 0;

  double get bookingGrandTotal =>
      totalWithInsurance + (priceBreakdown?.securityDeposit ?? 0);

  // Insurance state
  String? selectedInsuranceCoverage;
  double insurancePremium = 0.0;
  bool insuranceRequired = true; // Insurance is mandatory

  @override
  void initState() {
    super.initState();
    _checkVerificationOnInit();

    // Auto-fill user data from profile
    if (widget.userFullName != null && widget.userFullName!.isNotEmpty) {
      fullNameController.text = widget.userFullName!;
    }
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      emailController.text = widget.userEmail!;
    }
    if (widget.userContact != null && widget.userContact!.isNotEmpty) {
      contactController.text = widget.userContact!;
    }
    _calculatePrice();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    setState(() {
      priceBreakdown = PricingCalculator.calculatePrice(
        pricePerDay: basePrice,
        numberOfDays: numberOfDays,
        rentalPeriod: rentalPeriod,
        needsDelivery: false,
        deliveryDistance: 0.0,
        insuranceFee: insurancePremium,
      );
    });
  }

  Future<void> _selectInsurance() async {
    if (priceBreakdown == null) {
      _showError('Please complete booking details first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InsuranceSelectionScreen(
              bookingId: 0, // Will be set after booking creation
              userId: int.tryParse(widget.userId ?? '0') ?? 0,
              rentalAmount: priceBreakdown!.totalAmount,
              onInsuranceSelected: (coverageType, premium) {
                setState(() {
                  selectedInsuranceCoverage = coverageType;
                  insurancePremium = premium;
                  _calculatePrice(); // Recalculate price after insurance selection
                });
              },
            ),
      ),
    );
  }

  // Replace your _checkVerificationOnInit() method with this improved version:

  Future<void> _checkVerificationOnInit() async {
    print("[VERIFY] Starting verification check...");

    if (widget.userId == null || widget.userId!.isEmpty) {
      print("[ERROR] No user ID provided");
      if (!mounted) return;
      setState(() {
        isCheckingVerification = false;
        isVerifiedUser = false;
        verificationError = 'User not logged in';
      });
      return;
    }

    print("[VERIFY] User ID: ${widget.userId}");

    try {
      final url = Uri.parse(
        "${GlobalApiConfig.checkVerificationEndpoint}?user_id=${widget.userId}",
      );

      print("[HTTP] Calling API: $url");

      final response = await http
          .get(url)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      print("[HTTP] Response Status: ${response.statusCode}");
      print("[HTTP] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Debug: Print the exact response
        print("[VERIFY] Parsed JSON: $result");
        print("[VERIFY] is_verified value: ${result['is_verified']}");
        print(
          "[VERIFY] is_verified type: ${result['is_verified'].runtimeType}",
        );
        print("[VERIFY] can_add_car value: ${result['can_add_car']}");
        print("[VERIFY] Message: ${result['message']}");

        // Handle the response properly
        final isVerified = result['is_verified'];
        final canAddCar = result['can_add_car'];
        final message = result['message'] ?? 'Unknown status';

        if (!mounted) return;
        setState(() {
          // Handle both boolean and string values
          isVerifiedUser =
              (isVerified == true ||
                  isVerified == 1 ||
                  isVerified == "1" ||
                  isVerified == "true") &&
              (canAddCar == true ||
                  canAddCar == 1 ||
                  canAddCar == "1" ||
                  canAddCar == "true");
          isCheckingVerification = false;

          if (!isVerifiedUser) {
            verificationError = message;
            print("[ERROR] User not verified: $message");
          } else {
            print("[VERIFY] User is verified!");
          }
        });
      } else {
        print("[ERROR] HTTP Error: ${response.statusCode}");
        if (!mounted) return;
        setState(() {
          isCheckingVerification = false;
          isVerifiedUser = false;
          verificationError = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("[ERROR] Exception caught: $e");
      print("[ERROR] Exception type: ${e.runtimeType}");

      if (!mounted) return;
      setState(() {
        isCheckingVerification = false;
        isVerifiedUser = false;
        verificationError = 'Connection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _openMapDirections() async {
    if (widget.ownerLatitude != null && widget.ownerLongitude != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MapRouteScreen(
                destinationLat: widget.ownerLatitude!,
                destinationLng: widget.ownerLongitude!,
                locationName: widget.location,
                carName: widget.carName,
              ),
        ),
      );
    } else {
      final searchUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.location)}',
      );

      if (await canLaunchUrl(searchUrl)) {
        await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to open maps application'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    }
  }

  Future<void> _openAvailabilityCalendar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RenterAvailabilityCalendar(
              vehicleId: widget.carId,
              vehicleType: widget.vehicleType,
              vehicleName: widget.carName,
            ),
      ),
    );

    if (result == null) return;

    // RenterAvailabilityCalendar returns a map like:
    // {'start': DateTime?, 'end': DateTime?}
    // The generic type isn't guaranteed at runtime, so parse defensively.
    if (result is Map) {
      final dynamic rawStart = result['start'];
      final dynamic rawEnd = result['end'];

      DateTime? start;
      DateTime? end;

      if (rawStart is DateTime) {
        start = rawStart;
      } else if (rawStart is String) {
        start = DateTime.tryParse(rawStart);
      }

      if (rawEnd is DateTime) {
        end = rawEnd;
      } else if (rawEnd is String) {
        end = DateTime.tryParse(rawEnd);
      }

      if (start == null) return;
      end ??= start;

      // Normalize to date-only to avoid subtle time component issues.
      final normalizedStart = DateTime(start.year, start.month, start.day);
      final normalizedEnd = DateTime(end.year, end.month, end.day);

      setState(() {
        pickupDate = normalizedStart;
        returnDate = normalizedEnd;
        _calculatePrice();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,

            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show loading state while checking verification
    if (isCheckingVerification) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).iconTheme.color),
            SizedBox(height: 16),
            Text(
              'Verifying account...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              debugInfo,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    // Show error state if not verified
    if (!isVerifiedUser) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  color: Theme.of(context).colorScheme.error,
                  size: 64,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Access Denied',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your account is not verified.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
              SizedBox(height: 16),
              // DEBUG INFO
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).iconTheme.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEBUG',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      debugInfo,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    Text(
                      'isVerified: $isVerifiedUser',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isCheckingVerification = true;
                  });
                  _checkVerificationOnInit();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // VERIFIED - Show booking form
    return Column(
      children: [
        // Success indicator
        Container(
          padding: EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.verified,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Account Verified ✓',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCarInfoCard(),
                SizedBox(height: 24),
                Text(
                  'Renter Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
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
                _buildAvailabilityCalendarButton(),
                SizedBox(height: 16),
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
                if (_isSameDayTimeInvalid) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Return time must be after pickup time for same-day bookings.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 24),
                Text(
                  'Car Location',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                _buildLocationWithMap(),
                SizedBox(height: 24),
                _buildInsuranceSection(),
                SizedBox(height: 24),
                _buildPriceBreakdown(),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  // ... [Keep all your existing widget building methods unchanged]
  // _buildCarInfoCard, _buildDeliveryToggle, _buildTextField, etc.

  Widget _buildCarInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: OptimizedNetworkImage(
              imageUrl: widget.carImage,
              width: 80,
              height: 60,
              fit: BoxFit.cover,
              errorIcon: widget.vehicleType.toLowerCase() == 'motorcycle' 
                  ? Icons.two_wheeler 
                  : Icons.directions_car,
              errorIconSize: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.carName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              color: Theme.of(context).disabledColor,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).disabledColor,
              size: 20,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
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

  Widget _buildAvailabilityCalendarButton() {
    return GestureDetector(
      onTap: _openAvailabilityCalendar,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupDate == null && returnDate == null
                            ? 'Select Rental Dates'
                            : 'Selected Dates',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        pickupDate == null && returnDate == null
                            ? 'Tap to check availability'
                            : '${DateFormat('MMM dd').format(pickupDate!)} - ${DateFormat('MMM dd, yyyy').format(returnDate!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.green.shade700,
                ),
              ],
            ),
            if (pickupDate != null && returnDate != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '$numberOfDays ${numberOfDays == 1 ? 'day' : 'days'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (rentalPeriod != 'Day') ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer, color: Colors.blue.shade700, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '$rentalPeriod rate · ${rentalPeriod == 'Weekly' ? '${(PricingCalculator.weeklyDiscountRate * 100).toStringAsFixed(0)}' : '${(PricingCalculator.monthlyDiscountRate * 100).toStringAsFixed(0)}'}% off',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWithMap() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.location,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          InkWell(
            onTap: _openMapDirections,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'View Route on Map',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            selectedInsuranceCoverage != null
                ? Colors.green.shade50
                : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              selectedInsuranceCoverage != null
                  ? Colors.green.shade200
                  : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selectedInsuranceCoverage != null
                    ? Icons.verified_user
                    : Icons.warning_amber_rounded,
                color:
                    selectedInsuranceCoverage != null
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedInsuranceCoverage != null
                          ? 'Insurance Selected ?'
                          : 'Insurance Required',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            selectedInsuranceCoverage != null
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      selectedInsuranceCoverage != null
                          ? '${selectedInsuranceCoverage!.toUpperCase()} Coverage - ${InsuranceService.formatCurrency(insurancePremium)}'
                          : 'All bookings must have insurance coverage',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectInsurance,
              icon: Icon(
                selectedInsuranceCoverage != null ? Icons.edit : Icons.shield,
                size: 18,
              ),
              label: Text(
                selectedInsuranceCoverage != null
                    ? 'Change Coverage'
                    : 'Select Insurance',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedInsuranceCoverage != null
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    if (priceBreakdown == null) return SizedBox();

    final double securityDeposit = priceBreakdown!.securityDeposit;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          _buildBreakdownRow(
            'Base Rental',
            '${PricingCalculator.formatCurrency(priceBreakdown!.baseRental)}',
            subtitle:
                '₱${priceBreakdown!.pricePerDay.toStringAsFixed(0)} × ${priceBreakdown!.numberOfDays} days',
          ),

          _buildBreakdownRow(
            priceBreakdown!.discount > 0
                ? '$rentalPeriod Discount'
                : 'Discount',
            priceBreakdown!.discount > 0
                ? '-${PricingCalculator.formatCurrency(priceBreakdown!.discount)}'
                : 'None',
            isDiscount: priceBreakdown!.discount > 0,
            subtitle: priceBreakdown!.discount > 0
                ? '${priceBreakdown!.discountPercentage.toStringAsFixed(0)}% off'
                : 'Book 7+ days for 12% off, 30+ days for 25% off',
          ),

          if (insurancePremium > 0)
            _buildBreakdownRow(
              'Insurance Premium',
              InsuranceService.formatCurrency(insurancePremium),
              subtitle:
                  selectedInsuranceCoverage != null
                      ? '${selectedInsuranceCoverage!.toUpperCase()} coverage'
                      : null,
            ),

          Divider(height: 16, thickness: 1),
          _buildBreakdownRow(
            'Subtotal',
            PricingCalculator.formatCurrency(priceBreakdown!.subtotal),
          ),
          _buildBreakdownRow(
            'Service Fee',
            PricingCalculator.formatCurrency(priceBreakdown!.serviceFee),
            subtitle: '5% platform fee',
          ),

          Divider(height: 24, thickness: 1.5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Total Rental',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                PricingCalculator.formatCurrency(totalWithInsurance),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Security Deposit Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.orange.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Security Deposit',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    Text(
                      PricingCalculator.formatCurrency(securityDeposit),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Refundable deposit (20% of rental). Will be returned after successful vehicle return without damages.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          Divider(height: 1, thickness: 1.5),
          SizedBox(height: 16),
          
          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total to Pay',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Rental + Deposit',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                PricingCalculator.formatCurrency(bookingGrandTotal),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),
          Text(
            'Effective rate: ${PricingCalculator.formatCurrency(priceBreakdown!.effectiveDailyRate + (insurancePremium / numberOfDays))}/day',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String amount, {
    String? subtitle,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDiscount ? Colors.green.shade700 : null,
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
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
        color: Theme.of(context).colorScheme.surface,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            backgroundColor: Theme.of(context).iconTheme.color,

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
                PricingCalculator.formatCurrency(bookingGrandTotal),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.surface,

                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '  •  ',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 16,
                ),
              ),
              Text(
                'Pay Now',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.surface,

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
    if (!_isValidEmail(emailController.text.trim())) {
      _showError('Please enter a valid email address');
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
    // Validate insurance selection
    if (insuranceRequired && selectedInsuranceCoverage == null) {
      _showError('Please select an insurance coverage to proceed');
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _proceedToPayment() {
    if (_isSameDayTimeInvalid) {
      _showError('Return time must be after pickup time for same-day bookings.');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirm Booking',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('Car', widget.carName),
                    _buildSummaryRow('Rental Period', rentalPeriod),
                    _buildSummaryRow(
                      'Duration',
                      '$numberOfDays day${numberOfDays > 1 ? "s" : ""}',
                    ),
                    _buildSummaryRow(
                      'Pickup',
                      pickupDate != null
                          ? '${DateFormat('MMM dd, yyyy').format(pickupDate!)} at ${pickupTime.format(context)}'
                          : 'Not set',
                    ),
                    _buildSummaryRow(
                      'Return',
                      returnDate != null
                          ? '${DateFormat('MMM dd, yyyy').format(returnDate!)} at ${returnTime.format(context)}'
                          : 'Not set',
                    ),
                    _buildSummaryRow('Location', widget.location),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total to Pay',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          PricingCalculator.formatCurrency(bookingGrandTotal),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payment,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You will proceed to GCash payment to complete your booking.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processPayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).iconTheme.color,

                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Proceed to Payment',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.surface,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GCashPaymentScreen(
          bookingId: 0,
          vehicleType: widget.vehicleType,
          carId: widget.carId,
          carName: widget.carName,
          carImage: widget.carImage,
          ownerId: widget.ownerId,
          userId: widget.userId!,
          fullName: fullNameController.text.trim(),
          email: emailController.text.trim(),
          contact: contactController.text.trim(),
          pickupDate: DateFormat('yyyy-MM-dd').format(pickupDate!),
          returnDate: DateFormat('yyyy-MM-dd').format(returnDate!),
          pickupTime: '${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
          returnTime: '${returnTime.hour.toString().padLeft(2, '0')}:${returnTime.minute.toString().padLeft(2, '0')}',
          rentalPeriod: rentalPeriod,
          needsDelivery: false,
          baseRental: priceBreakdown!.baseRental,
          discount: priceBreakdown!.discount,
          insurancePremium: insurancePremium,
          totalAmount: totalWithInsurance,
          securityDeposit: priceBreakdown!.securityDeposit,
          serviceFee: priceBreakdown!.serviceFee,
        ),
      ),
    );
  }

}
