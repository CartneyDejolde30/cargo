class Booking {
  final int bookingId;
  final int carId;
  final int ownerId;
  final String carName;
  final String ownerAvatar;
  final String ownerPhone;

  final String carImage;
  final String location;
  final String pickupDate;
  final String pickupTime;
  final String returnDate;
  final String returnTime;
  final String totalPrice;
  final String status;
  final String ownerName;

  Booking({
    required this.bookingId,
    required this.carId,
    required this.ownerAvatar,
    required this.ownerId,
  

    required this.carName,
      required this.ownerPhone,
    required this.carImage,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.totalPrice,
    required this.status,
    required this.ownerName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
  return Booking(
    bookingId: json['bookingId'],
    carId: json['carId'],
    ownerAvatar: json['ownerAvatar'] ?? '',
ownerPhone: json['ownerPhone'] ?? '',

    ownerId: json['ownerId'],
    carName: json['carName'] ?? '',
    carImage: json['carImage'] ?? '',
    location: json['location'] ?? '',
    pickupDate: json['pickupDate'] ?? '',
    pickupTime: json['pickupTime'] ?? '',
    returnDate: json['returnDate'] ?? '',
    returnTime: json['returnTime'] ?? '',
    totalPrice: (json['totalPrice'] as num).toString(),

    // 🔥 Normalize status here
    status: json['status']
        .toString()
        .trim()
        .toLowerCase(),

    ownerName: json['ownerName'] ?? '',
  );
}

}
