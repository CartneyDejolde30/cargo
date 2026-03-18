class BookingRequest {
  final String bookingId;
  final String carName;
  final String carImage;
  final String totalAmount;
  final String pickupDate;
  final String returnDate;
  final String rentalPeriod;
  final String fullName;
  final String contact;
  final String email;
  final String location;
  final String seats;
  final String transmission;
  // Price breakdown fields
  final double pricePerDay;
  final double baseRental;
  final double discount;
  final double insurancePremium;
  final double serviceFee;
  final double securityDeposit;
  final double grandTotal;
  final int rentalDays;

  BookingRequest({
    required this.bookingId,
    required this.carName,
    required this.carImage,
    required this.totalAmount,
    required this.pickupDate,
    required this.returnDate,
    required this.rentalPeriod,
    required this.fullName,
    required this.contact,
    required this.email,
    required this.location,
    required this.seats,
    required this.transmission,
    this.pricePerDay = 0,
    this.baseRental = 0,
    this.discount = 0,
    this.insurancePremium = 0,
    this.serviceFee = 0,
    this.securityDeposit = 0,
    this.grandTotal = 0,
    this.rentalDays = 1,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      bookingId: json['booking_id']?.toString() ?? '',
      carName: json['car_name'] ?? 'Unknown Car',
      carImage: json['car_image'] ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      pickupDate: json['pickup_date'] ?? '',
      returnDate: json['return_date'] ?? '',
      rentalPeriod: json['rental_period'] ?? '',
      fullName: json['renter_name'] ?? json['full_name'] ?? 'Unknown',
      contact: json['renter_contact'] ?? json['contact'] ?? 'N/A',
      email: json['renter_email'] ?? json['email'] ?? 'N/A',
      location: json['location'] ?? 'N/A',
      seats: json['seats'] ?? 'N/A',
      transmission: json['transmission'] ?? 'N/A',
      pricePerDay:      (json['price_per_day'] as num?)?.toDouble() ?? 0,
      baseRental:       (json['base_rental'] as num?)?.toDouble() ?? 0,
      discount:         (json['discount'] as num?)?.toDouble() ?? 0,
      insurancePremium: (json['insurance_premium'] as num?)?.toDouble() ?? 0,
      serviceFee:       (json['service_fee'] as num?)?.toDouble() ?? 0,
      securityDeposit:  (json['security_deposit'] as num?)?.toDouble() ?? 0,
      grandTotal:       (json['grand_total'] as num?)?.toDouble() ?? 0,
      rentalDays:       (json['rental_days'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'car_name': carName,
      'car_image': carImage,
      'total_amount': totalAmount,
      'pickup_date': pickupDate,
      'return_date': returnDate,
      'rental_period': rentalPeriod,
      'full_name': fullName,
      'contact': contact,
      'email': email,
      'location': location,
      'seats': seats,
      'transmission': transmission,
    };
  }
}
