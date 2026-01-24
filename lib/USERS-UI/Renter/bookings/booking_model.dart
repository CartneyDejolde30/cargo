class BookingSummary {
  final String? id;
  final String userId;
  final int carId;
  final String carName;
  final String carImage;
  final String location;

  final String ownerId;
  final String ownerName;
  final String ownerAvatar;

  // User Information
  final String fullName;
  final String email;
  final String contactNumber;
  final String gender;

  // Booking Details
  final bool bookWithDriver;
  final String rentalPeriod; // 'Day', 'Weekly', 'Monthly'
  final DateTime pickupDate;
  final DateTime returnDate;
  final String pickupTime; // "HH:mm"
  final String returnTime;

  // Pricing
  final double pricePerDay;
  final double driverFee;
  final int numberOfDays;
  final double totalAmount;

  // Status & Metadata
  final String status; // 'pending', 'confirmed', 'active', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentId;
  final String? paymentMethod;

  const BookingSummary({
    this.id,
    required this.userId,
    required this.carId,
    required this.carName,
    required this.carImage,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
    required this.location,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.gender,
    required this.bookWithDriver,
    required this.rentalPeriod,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.returnTime,
    required this.pricePerDay,
    required this.driverFee,
    required this.numberOfDays,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.paymentId,
    this.paymentMethod,
  });

  // ----------------------
  // TO JSON
  // ----------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'car_id': carId,
      'car_name': carName,
      'car_image': carImage,
      'location': location,
      'full_name': fullName,
      'email': email,
      'contact': contactNumber,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_avatar': ownerAvatar,
      'gender': gender,
      'book_with_driver': bookWithDriver,
      'rental_period': rentalPeriod,
      'pickup_date': pickupDate.toIso8601String(),
      'return_date': returnDate.toIso8601String(),
      'pickup_time': pickupTime,
      'return_time': returnTime,
      'price_per_day': pricePerDay,
      'driver_fee': driverFee,
      'number_of_days': numberOfDays,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payment_id': paymentId,
      'payment_method': paymentMethod,
    };
  }

  // ----------------------
  // FROM JSON
  // ----------------------
  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      carId: int.tryParse(json['car_id'].toString()) ?? 0,
      carName: json['car_name'] ?? '',
      carImage: json['car_image'] ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      ownerName: json['owner_name'] ?? 'Car Owner',
      ownerAvatar: json['owner_avatar'] ?? '',
      location: json['location'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      contactNumber: json['contact'] ?? '',
      gender: json['gender'] ?? 'Male',
      bookWithDriver: json['book_with_driver'] == true ||
          json['book_with_driver'] == 1 ||
          json['book_with_driver'] == "1",
      rentalPeriod: json['rental_period'] ?? 'Day',
      pickupDate: DateTime.parse(json['pickup_date']),
      returnDate: DateTime.parse(json['return_date']),
      pickupTime: json['pickup_time'] ?? '09:00',
      returnTime: json['return_time'] ?? '17:00',
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0.0,
      driverFee: (json['driver_fee'] as num?)?.toDouble() ?? 0.0,
      numberOfDays: int.tryParse(json['number_of_days'].toString()) ?? 1,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      paymentId: json['payment_id']?.toString(),
      paymentMethod: json['payment_method'],
    );
  }

  // ----------------------
  // COPY WITH
  // ----------------------
  BookingSummary copyWith({
    String? id,
    String? userId,
    int? carId,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    String? carName,
    String? carImage,
    String? location,
    String? fullName,
    String? email,
    String? contactNumber,
    String? gender,
    bool? bookWithDriver,
    String? rentalPeriod,
    DateTime? pickupDate,
    DateTime? returnDate,
    String? pickupTime,
    String? returnTime,
    double? pricePerDay,
    double? driverFee,
    int? numberOfDays,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentId,
    String? paymentMethod,
  }) {
    return BookingSummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      carName: carName ?? this.carName,
      carImage: carImage ?? this.carImage,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      location: location ?? this.location,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      gender: gender ?? this.gender,
      bookWithDriver: bookWithDriver ?? this.bookWithDriver,
      rentalPeriod: rentalPeriod ?? this.rentalPeriod,
      pickupDate: pickupDate ?? this.pickupDate,
      returnDate: returnDate ?? this.returnDate,
      pickupTime: pickupTime ?? this.pickupTime,
      returnTime: returnTime ?? this.returnTime,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      driverFee: driverFee ?? this.driverFee,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
