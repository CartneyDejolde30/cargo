class Booking {
  final int bookingId;
  final String carName;
  final String carImage;
  final String location;

  final String pickupDate;
  final String pickupTime;
  final String returnDate;
  final String returnTime;

  final String totalPrice;
  final String status;

  Booking({
    required this.bookingId,
    required this.carName,
    required this.carImage,
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.totalPrice,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: int.parse(json['bookingId'].toString()),
      carName: json['carName'],
      carImage: json['carImage'],
      location: json['location'],
      pickupDate: json['pickupDate'],
      pickupTime: json['pickupTime'],
      returnDate: json['returnDate'],
      returnTime: json['returnTime'],
      totalPrice: json['totalPrice'],
      status: json['status'],
    );
  }
}
