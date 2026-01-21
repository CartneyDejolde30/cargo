// lib/USERS-UI/Owner/dashboard/booking_model.dart

class Booking {
  final int id;
  final String carFullName;
  final String carImage;
  final String renterName;
  final String startDate;
  final String endDate;
  final String status;
  final String totalAmount;
  final String rentalPeriod;

  Booking({
    required this.id,
    required this.carFullName,
    required this.carImage,
    required this.renterName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalAmount,
    required this.rentalPeriod,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: int.tryParse(json['booking_id']?.toString() ?? '0') ?? 0,
      carFullName: json['car_full_name']?.toString() ?? 'Unknown Car',
      carImage: json['car_image']?.toString() ?? 'uploads/default_car.png',
      renterName: json['renter_name']?.toString() ?? 'Unknown Renter',
      startDate: json['pickup_date']?.toString() ?? '',
      endDate: json['return_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      totalAmount: json['total_amount']?.toString() ?? '0',
      rentalPeriod: json['rental_period']?.toString() ?? 'Day',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': id,
      'car_full_name': carFullName,
      'car_image': carImage,
      'renter_name': renterName,
      'pickup_date': startDate,
      'return_date': endDate,
      'status': status,
      'total_amount': totalAmount,
      'rental_period': rentalPeriod,
    };
  }
}
