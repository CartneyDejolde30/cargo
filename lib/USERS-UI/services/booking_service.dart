import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/USERS-UI/Renter/models/booking.dart';

class BookingService {

  // =========================
  // GET MY BOOKINGS (REAL DATA)
  // =========================
  static Future<List<Booking>> getMyBookings(String userId) async {
  final response = await http.get(
    Uri.parse(
      'http://10.77.127.2/carGOAdmin/api/get_my_bookings.php?user_id=$userId',
    ),
  );

  print('RAW RESPONSE: ${response.body}');

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    if (jsonData['bookings'] == null) {
      return [];
    }

    final List list = jsonData['bookings'];

    return list.map((e) => Booking.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load bookings');
  }
}




  // =========================
  // CANCEL BOOKING
  // =========================
  static Future<bool> cancelBooking({
    required int bookingId,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse(
        'http://10.77.127.2/carGOAdmin/api/cancel_booking.php',
      ),
      body: {
        'booking_id': bookingId.toString(),
        'user_id': userId,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}
