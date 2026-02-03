import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/renter_vehicle_availability_widget.dart';
import 'booking_screen.dart';

/// Enhanced Booking Screen with automatic availability checking
/// Shows availability calendar before booking
class BookingScreenWithAvailability extends StatefulWidget {
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

  const BookingScreenWithAvailability({
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
  State<BookingScreenWithAvailability> createState() => _BookingScreenWithAvailabilityState();
}

class _BookingScreenWithAvailabilityState extends State<BookingScreenWithAvailability> {
  DateTime? _selectedPickupDate;
  DateTime? _selectedReturnDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book ${widget.carName}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              widget.vehicleType == 'car' ? 'Car Rental' : 'Motorcycle Rental',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedPickupDate != null && _selectedReturnDate != null)
            TextButton(
              onPressed: _proceedToBooking,
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Info Card
            _buildVehicleInfoCard(),
            
            const SizedBox(height: 16),
            
            // Availability Calendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RenterVehicleAvailabilityWidget(
                vehicleId: widget.carId,
                vehicleType: widget.vehicleType,
                vehicleName: widget.carName,
                onDateRangeSelected: (start, end) {
                  setState(() {
                    _selectedPickupDate = start;
                    _selectedReturnDate = end;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pricing Info
            if (_selectedPickupDate != null && _selectedReturnDate != null)
              _buildPricingInfo(),
            
            const SizedBox(height: 16),
            
            // Important Notes
            _buildImportantNotes(),
            
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _selectedPickupDate != null && _selectedReturnDate != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildVehicleInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.carImage,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: Icon(Icons.directions_car, color: Colors.grey[400], size: 40),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.carName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₱${widget.pricePerDay}/day',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
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

  Widget _buildPricingInfo() {
    final days = _selectedReturnDate!.difference(_selectedPickupDate!).inDays + 1;
    final pricePerDay = double.parse(widget.pricePerDay);
    final totalPrice = pricePerDay * days;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Daily Rate', '₱${pricePerDay.toStringAsFixed(2)}'),
          _buildPriceRow('Number of Days', '$days days'),
          const Divider(height: 24),
          _buildPriceRow(
            'Total',
            '₱${totalPrice.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Important Notes',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNote('Select available dates from the calendar above'),
          _buildNote('Dates marked in blue are already booked'),
          _buildNote('Dates marked in red are blocked by the owner'),
          _buildNote('Your booking will be pending until owner approval'),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _proceedToBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline),
              const SizedBox(width: 8),
              Text(
                'Continue to Booking',
                style: GoogleFonts.poppins(
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

  void _proceedToBooking() {
    if (_selectedPickupDate == null || _selectedReturnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select pickup and return dates',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to original booking screen with pre-selected dates
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          carId: widget.carId,
          vehicleType: widget.vehicleType,
          carName: widget.carName,
          carImage: widget.carImage,
          pricePerDay: widget.pricePerDay,
          ownerId: widget.ownerId,
          location: widget.location,
          userId: widget.userId,
          userFullName: widget.userFullName,
          userContact: widget.userContact,
          userEmail: widget.userEmail,
          userMunicipality: widget.userMunicipality,
          ownerLatitude: widget.ownerLatitude,
          ownerLongitude: widget.ownerLongitude,
        ),
      ),
    );
  }
}
