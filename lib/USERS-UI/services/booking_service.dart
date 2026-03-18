import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cargo/config/api_config.dart';
import 'package:cargo/USERS-UI/Renter/models/booking.dart';

class BookingService {

  // =========================
  // GET MY BOOKINGS (REAL DATA)
  // =========================
  static Future<List<Booking>> getMyBookings(String userId) async {
  final response = await http.get(
    Uri.parse(
      '${GlobalApiConfig.getMyBookingsEndpoint}?user_id=$userId',
    ),
  );

  debugPrint('RAW RESPONSE: ${response.body}');

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    if (jsonData['bookings'] == null) {
      return [];
    }

    final List list = jsonData['bookings'];

    return list.map((e) => Booking.fromJson(e)).toList();
  } else if (response.statusCode == 401 || response.statusCode == 403) {
    throw Exception('Session expired. Please log in again.');
  } else {
    throw Exception('Failed to load bookings (HTTP ${response.statusCode})');
  }
}




  // =========================
  // CANCEL BOOKING
  // =========================
  static Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    required String userId,
  }) async {
    try {
      print('🚀 Cancelling booking...');
      print('   Booking ID: $bookingId');
      print('   User ID: $userId');
      print('   Endpoint: ${GlobalApiConfig.cancelBookingEndpoint}');
      
      final response = await http.post(
        Uri.parse(
          GlobalApiConfig.cancelBookingEndpoint,
        ),
        body: {
          'booking_id': bookingId.toString(),
          'user_id': userId,
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Unknown response',
          'current_status': data['current_status'],
        };
      }
      
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      print('❌ Cancel booking error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
