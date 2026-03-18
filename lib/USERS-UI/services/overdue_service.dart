import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cargo/config/api_config.dart';
import '../models/overdue_booking.dart';

class OverdueService {
  static String get baseUrl => GlobalApiConfig.baseUrl; // Production

  /// Get overdue bookings for an owner
  Future<List<OverdueBooking>> getOwnerOverdueBookings(int ownerId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}api/overdue/get_overdue_bookings.php?owner_id=$ownerId&severity=all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<OverdueBooking> bookings = [];
          for (var item in data['data']) {
            bookings.add(OverdueBooking.fromJson(item));
          }
          return bookings;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching owner overdue bookings: $e');
      return [];
    }
  }

  /// Check if a specific booking is overdue (for renter)
  /// Uses dedicated endpoint for real-time overdue detection
  Future<OverdueBooking?> checkBookingOverdue(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}api/overdue/check_booking_overdue.php?booking_id=$bookingId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['is_overdue'] == true) {
          return OverdueBooking.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error checking booking overdue: $e');
      return null;
    }
  }

  /// Parses a return date + time string into a DateTime.
  /// Handles both 24-hour ("08:50:00") and 12-hour ("08:50 AM") formats.
  DateTime? _parseReturnDateTime(String returnDate, String returnTime) {
    final date = returnDate.trim();
    final time = returnTime.trim();
    // Try ISO / 24-hour format first
    final direct = DateTime.tryParse('$date $time') ?? DateTime.tryParse('${date}T$time');
    if (direct != null) return direct;
    // Handle 12-hour AM/PM format (e.g. "08:50 AM")
    final amPmMatch = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)$', caseSensitive: false).firstMatch(time);
    if (amPmMatch != null) {
      int hour = int.parse(amPmMatch.group(1)!);
      final minute = int.parse(amPmMatch.group(2)!);
      final second = int.tryParse(amPmMatch.group(3) ?? '') ?? 0;
      final isPm = amPmMatch.group(4)!.toUpperCase() == 'PM';
      if (hour == 12) hour = isPm ? 12 : 0;
      else if (isPm) hour += 12;
      final dateParts = date.split('-');
      if (dateParts.length == 3) {
        return DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]),
            int.parse(dateParts[2]), hour, minute, second);
      }
    }
    return null;
  }

  /// Check if booking is overdue based on return date/time (client-side calculation)
  /// This is a fallback when API is unavailable
  bool isBookingOverdueLocal(String returnDate, String returnTime) {
    final returnDateTime = _parseReturnDateTime(returnDate, returnTime);
    if (returnDateTime == null) {
      print('Error parsing return date/time: $returnDate $returnTime');
      return false;
    }
    return DateTime.now().isAfter(returnDateTime);
  }

  /// Calculate hours overdue (client-side)
  int calculateHoursOverdue(String returnDate, String returnTime) {
    final returnDateTime = _parseReturnDateTime(returnDate, returnTime);
    if (returnDateTime == null) {
      print('Error calculating hours overdue: $returnDate $returnTime');
      return 0;
    }
    final now = DateTime.now();
    return now.isAfter(returnDateTime) ? now.difference(returnDateTime).inHours : 0;
  }

  /// Request a rental extension
  Future<Map<String, dynamic>> requestExtension({
    required int bookingId,
    required int userId,
    required DateTime requestedReturnDate,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}api/extensions/request_extension.php'),
        body: {
          'booking_id': bookingId.toString(),
          'user_id': userId.toString(),
          'requested_return_date': requestedReturnDate.toIso8601String().split('T')[0],
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to request extension'};
    } catch (e) {
      print('Error requesting extension: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Approve an extension request (owner)
  Future<Map<String, dynamic>> approveExtension({
    required int extensionId,
    required int ownerId,
    String reason = 'Approved',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}api/extensions/manage_extension.php'),
        body: {
          'extension_id': extensionId.toString(),
          'owner_id': ownerId.toString(),
          'action': 'approve',
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to approve extension'};
    } catch (e) {
      print('Error approving extension: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Reject an extension request (owner)
  Future<Map<String, dynamic>> rejectExtension({
    required int extensionId,
    required int ownerId,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}api/extensions/manage_extension.php'),
        body: {
          'extension_id': extensionId.toString(),
          'owner_id': ownerId.toString(),
          'action': 'reject',
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to reject extension'};
    } catch (e) {
      print('Error rejecting extension: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calculate late fee for given hours
  double calculateLateFee(int hoursOverdue) {
    const int graceHours = 2;
    const double tier1Rate = 300.0;
    const double tier2Rate = 500.0;
    const double tier3Rate = 2000.0;

    if (hoursOverdue <= graceHours) return 0.0;

    double fee = 0.0;

    if (hoursOverdue > graceHours && hoursOverdue <= 6) {
      fee = (hoursOverdue - graceHours) * tier1Rate;
    } else if (hoursOverdue > 6 && hoursOverdue < 24) {
      final tier1Hours = 6 - graceHours;
      fee = (tier1Hours * tier1Rate) + ((hoursOverdue - 6) * tier2Rate);
    } else {
      final daysLate = (hoursOverdue / 24).floor();
      final remainingHours = hoursOverdue % 24;

      final tier1Hours = 6 - graceHours;
      fee = (tier1Hours * tier1Rate) + (18 * tier2Rate) + (daysLate * tier3Rate);

      if (remainingHours > graceHours) {
        if (remainingHours <= 6) {
          fee += (remainingHours - graceHours) * tier1Rate;
        } else {
          fee += (tier1Hours * tier1Rate) + ((remainingHours - 6) * tier2Rate);
        }
      }
    }

    return fee;
  }

  /// Format late fee for display
  String formatLateFee(double amount) {
    return '₱${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}
