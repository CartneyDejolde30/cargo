class Booking {
  final int bookingId;
  final int carId;
  final int ownerId;
  final String carName;
  final String ownerAvatar;
  final String ownerPhone;

  final String carImage;
  final String location;
  final double? latitude;
  final double? longitude;
  final String pickupDate;
  final String pickupTime;
  final String returnDate;
  final String returnTime;
  final String totalPrice;
  final String status;
  final String ownerName;
  final String? refundStatus;
  final String? escrowStatus;
  final bool isReviewed;
  final bool tripStarted;
  final double? odometerStart;
  // Price breakdown fields
  final double pricePerDay;
  final double baseRental;
  final double discount;
  final double insurancePremium;
  final double serviceFee;
  final double securityDeposit;
  final double grandTotal;
  final int rentalDays;
  final String rentalPeriod;

  Booking({
    required this.bookingId,
    required this.carId,
    required this.ownerAvatar,
    required this.ownerId,
    required this.carName,
    required this.ownerPhone,
    required this.carImage,
    required this.location,
    this.latitude,
    this.longitude,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.totalPrice,
    required this.status,
    required this.ownerName,
    this.refundStatus,
    this.escrowStatus,
    this.isReviewed = false,
    this.tripStarted = false,
    this.odometerStart,
    this.pricePerDay = 0,
    this.baseRental = 0,
    this.discount = 0,
    this.insurancePremium = 0,
    this.serviceFee = 0,
    this.securityDeposit = 0,
    this.grandTotal = 0,
    this.rentalDays = 1,
    this.rentalPeriod = 'Day',
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
  final rawCarImage = json['carImage']?.toString() ?? '';
  final rawOwnerAvatar = json['ownerAvatar']?.toString() ?? '';

  return Booking(
    bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
    carId: (json['carId'] as num?)?.toInt() ?? 0,
    ownerAvatar: rawOwnerAvatar.trim(),
    ownerPhone: json['ownerPhone']?.toString() ?? '',
    ownerId: (json['ownerId'] as num?)?.toInt() ?? 0,
    carName: json['carName']?.toString() ?? '',
    carImage: rawCarImage.trim(),
    location: json['location']?.toString() ?? '',
    latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
    longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    pickupDate: json['pickupDate']?.toString() ?? '',
    pickupTime: json['pickupTime']?.toString() ?? '',
    returnDate: json['returnDate']?.toString() ?? '',
    returnTime: json['returnTime']?.toString() ?? '',
    totalPrice: (json['totalPrice'] as num?)?.toString() ?? '0',
    status: json['status']?.toString().trim().toLowerCase() ?? 'unknown',
    ownerName: json['ownerName'] ?? '',
    refundStatus: json['refundStatus']?.toString(),
    escrowStatus: json['escrowStatus']?.toString(),
    isReviewed: json['isReviewed'] == 1 || json['isReviewed'] == true,
    tripStarted: json['tripStarted'] == 1 || json['tripStarted'] == true ||
                 json['status']?.toString().toLowerCase() == 'ongoing',
    odometerStart: json['odometerStart'] != null ? (json['odometerStart'] as num).toDouble() : null,
    // Breakdown fields
    pricePerDay:      (json['pricePerDay'] as num?)?.toDouble() ?? 0,
    baseRental:       (json['baseRental'] as num?)?.toDouble() ?? 0,
    discount:         (json['discount'] as num?)?.toDouble() ?? 0,
    insurancePremium: (json['insurancePremium'] as num?)?.toDouble() ?? 0,
    serviceFee:       (json['serviceFee'] as num?)?.toDouble() ?? 0,
    securityDeposit:  (json['securityDeposit'] as num?)?.toDouble() ?? 0,
    grandTotal:       (json['grandTotal'] as num?)?.toDouble() ?? 0,
    rentalDays:       (json['rentalDays'] as num?)?.toInt() ?? 1,
    rentalPeriod:     json['rentalPeriod']?.toString() ?? 'Day',
  );
}

}
