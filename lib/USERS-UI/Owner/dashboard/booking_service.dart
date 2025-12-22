import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../Owner/mycar/api_constants.dart';
import './booking_model.dart';

class BookingService {
  /* ---------------- FETCH RECENT BOOKINGS ---------------- */
  Future<List<Booking>> fetchRecentBookings(String ownerId, {int limit = 5}) async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}api/recent_bookings.php?owner_id=$ownerId&limit=$limit");
      final response = await http.get(url).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['bookings'] is List) {
          return (data['bookings'] as List)
              .map((booking) => Booking.fromJson(booking))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching recent bookings: $e");
    }

    return [];
  }

  /* ---------------- FETCH UPCOMING BOOKINGS ---------------- */
  Future<List<Booking>> fetchUpcomingBookings(String ownerId) async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}api/upcoming_bookings.php?owner_id=$ownerId");
      final response = await http.get(url).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['bookings'] is List) {
          return (data['bookings'] as List)
              .map((booking) => Booking.fromJson(booking))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching upcoming bookings: $e");
    }

    return [];
  }

  /* ---------------- FETCH PENDING REQUESTS ---------------- */
  Future<List<Booking>> fetchPendingRequests(String ownerId) async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}api/pending_bookings.php?owner_id=$ownerId");
      final response = await http.get(url).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['bookings'] is List) {
          return (data['bookings'] as List)
              .map((booking) => Booking.fromJson(booking))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching pending requests: $e");
    }

    return [];
  }
}