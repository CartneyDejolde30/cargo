// lib/USERS-UI/Owner/dashboard/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../mycar/api_config.dart';
import './booking_model.dart';

class BookingService {
  /* ---------------- FETCH RECENT BOOKINGS ---------------- */
 Future<List<Map<String, dynamic>>> fetchCancelledBookings(String ownerId) async {
  try {
    final url = Uri.parse("${ApiConfig.cancelledBookingsEndpoint}?owner_id=$ownerId");
    final response = await http.get(url).timeout(ApiConfig.apiTimeout);

    debugPrint("📡 Cancelled Bookings API: $url");
    debugPrint("📥 Response: ${response.body}");

    if (response.statusCode == 200) {

      if (!response.body.trim().startsWith("{")) {
        debugPrint("❌ Not JSON Response:");
        debugPrint(response.body);
        return [];
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['bookings'] is List) {
        return List<Map<String, dynamic>>.from(data['bookings']);
      } else {
        debugPrint("⚠️ API returned success=false: ${data['message']}");
      }
    } else {
      debugPrint("⚠️ HTTP Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ Error fetching cancelled bookings: $e");
    return [];
  }

  return [];
}


  /* ---------------- FETCH UPCOMING BOOKINGS ---------------- */
  Future<List<Booking>> fetchUpcomingBookings(String ownerId) async {
    try {
      final url = Uri.parse("${ApiConfig.upcomingBookingsEndpoint}?owner_id=$ownerId");
      final response = await http.get(url).timeout(ApiConfig.apiTimeout);

      debugPrint("📡 Upcoming Bookings API: $url");
      debugPrint("📥 Response: ${response.body}");

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
      rethrow;
    }

    return [];
  }

  /* ---------------- FETCH PENDING REQUESTS ---------------- */
  Future<List<Map<String, dynamic>>> fetchPendingRequests(String ownerId) async {
    try {
      final url = Uri.parse("${ApiConfig.pendingRequestsEndpoint}?owner_id=$ownerId");
      final response = await http.get(url).timeout(ApiConfig.apiTimeout);

      debugPrint("📡 Pending Requests API: $url");
      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['requests'] is List) {
          return List<Map<String, dynamic>>.from(data['requests']);
        } else {
          debugPrint("⚠️ API returned success=false: ${data['message']}");
        }
      } else {
        debugPrint("⚠️ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching pending requests: $e");
      rethrow;
    }

    return [];
  }

  /* ---------------- FETCH ACTIVE BOOKINGS ---------------- */
  Future<List<Map<String, dynamic>>> fetchActiveBookings(String ownerId) async {
    try {
      final url = Uri.parse("${ApiConfig.activeBookingsEndpoint}?owner_id=$ownerId");
      final response = await http.get(url).timeout(ApiConfig.apiTimeout);

      debugPrint("📡 Active Bookings API: $url");
      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['bookings'] is List) {
          return List<Map<String, dynamic>>.from(data['bookings']);
        } else {
          debugPrint("⚠️ API returned success=false: ${data['message']}");
        }
      } else {
        debugPrint("⚠️ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching active bookings: $e");
      rethrow;
    }

    return [];
  }

  /* ---------------- NEW: FETCH CANCELLED BOOKINGS ---------------- */


  /* ---------------- NEW: FETCH REJECTED BOOKINGS ---------------- */
  Future<List<Map<String, dynamic>>> fetchRejectedBookings(String ownerId) async {
  try {
    final url = Uri.parse("${ApiConfig.rejectedBookingsEndpoint}?owner_id=$ownerId");
    final response = await http.get(url).timeout(ApiConfig.apiTimeout);

    debugPrint("📡 Rejected Bookings API: $url");
    debugPrint("📥 Response: ${response.body}");

    if (response.statusCode == 200) {

      if (!response.body.trim().startsWith("{")) {
        debugPrint("❌ Not JSON Response:");
        debugPrint(response.body);
        return [];
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['bookings'] is List) {
        return List<Map<String, dynamic>>.from(data['bookings']);
      } else {
        debugPrint("⚠️ API returned success=false: ${data['message']}");
      }
    } else {
      debugPrint("⚠️ HTTP Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ Error fetching rejected bookings: $e");
    return [];
  }

  return [];
}

/* ---------------- FETCH RECENT BOOKINGS ---------------- */
Future<List<Booking>> fetchRecentBookings(String ownerId, {int limit = 5}) async {
  try {
    final url = Uri.parse("${ApiConfig.recentBookingsEndpoint}?owner_id=$ownerId&limit=$limit");
    final response = await http.get(url).timeout(ApiConfig.apiTimeout);

    debugPrint("📡 Recent Bookings API: $url");
    debugPrint("📥 Response: ${response.body}");

    if (response.statusCode == 200) {

      if (!response.body.trim().startsWith("{")) {
        debugPrint("❌ Not JSON Response:");
        debugPrint(response.body);
        return [];
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['bookings'] is List) {
        return (data['bookings'] as List)
            .map((booking) => Booking.fromJson(booking))
            .toList();
      } else {
        debugPrint("⚠️ API returned success=false: ${data['message']}");
      }
    } else {
      debugPrint("⚠️ HTTP Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ Error fetching recent bookings: $e");
    return [];
  }

  return [];
}

  /* ---------------- APPROVE BOOKING ---------------- */
  Future<Map<String, dynamic>> approveBooking(String bookingId, String ownerId) async {
    try {
      final url = Uri.parse(ApiConfig.approveBookingEndpoint);
      final response = await http.post(
        url,
        body: {
          'booking_id': bookingId,
          'owner_id': ownerId,
        },
      ).timeout(ApiConfig.apiTimeout);

      debugPrint("📡 Approve Booking API: $url");
      debugPrint("📤 Body: booking_id=$bookingId, owner_id=$ownerId");
      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint("❌ Error approving booking: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /* ---------------- REJECT BOOKING ---------------- */
  Future<Map<String, dynamic>> rejectBooking(
    String bookingId, 
    String ownerId, 
    String reason
  ) async {
    try {
      final url = Uri.parse(ApiConfig.rejectBookingEndpoint);
      final response = await http.post(
        url,
        body: {
          'booking_id': bookingId,
          'owner_id': ownerId,
          'reason': reason,
        },
      ).timeout(ApiConfig.apiTimeout);

      debugPrint("📡 Reject Booking API: $url");
      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint("❌ Error rejecting booking: $e");
      return {'success': false, 'message': 'Network error: $e'};
      
    }
  }

  /* ---------------- END TRIP/MARK AS COMPLETED ---------------- */
  Future<Map<String, dynamic>> endTrip(String bookingId, String ownerId) async {
    try {
      final url = Uri.parse(ApiConfig.endTripEndpoint);
      final response = await http.post(
        url,
        body: {
          'booking_id': bookingId,
          'owner_id': ownerId,
        },
      ).timeout(ApiConfig.apiTimeout);

      debugPrint("📡 End Trip API: $url");
      debugPrint("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint("❌ Error ending trip: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}