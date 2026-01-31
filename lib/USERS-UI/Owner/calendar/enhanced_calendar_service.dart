import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../mycar/api_constants.dart';

/// Enhanced Calendar Service with advanced features
class EnhancedCalendarService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get blocked dates with booking information
  Future<Map<String, dynamic>> getBlockedDates({
    required int vehicleId,
    required String vehicleType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/availability/get_blocked_dates.php?'
          'vehicle_id=$vehicleId&'
          'vehicle_type=$vehicleType&'
          'start_date=${_formatDate(startDate)}&'
          'end_date=${_formatDate(endDate)}',
        ),
      ).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'blocked_dates': (data['blocked_dates'] as List)
                .map((date) => DateTime.parse(date))
                .toSet(),
            'booked_dates': (data['booked_dates'] as List)
                .map((date) => DateTime.parse(date))
                .toSet(),
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching blocked dates: $e');
    }

    return {
      'success': false,
      'blocked_dates': <DateTime>{},
      'booked_dates': <DateTime>{},
    };
  }

  /// Block multiple dates
  Future<Map<String, dynamic>> blockDates({
    required int ownerId,
    required int vehicleId,
    required String vehicleType,
    required List<DateTime> dates,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/availability/block_dates.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_id': ownerId,
          'vehicle_id': vehicleId,
          'vehicle_type': vehicleType,
          'dates': dates.map((d) => _formatDate(d)).toList(),
          'reason': reason,
        }),
      ).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'blocked_count': data['blocked_count'] ?? 0,
          'already_blocked': data['already_blocked'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('❌ Error blocking dates: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }

    return {
      'success': false,
      'message': 'Failed to block dates',
    };
  }

  /// Unblock multiple dates
  Future<Map<String, dynamic>> unblockDates({
    required int ownerId,
    required int vehicleId,
    required String vehicleType,
    required List<DateTime> dates,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/availability/unblock_dates.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_id': ownerId,
          'vehicle_id': vehicleId,
          'vehicle_type': vehicleType,
          'dates': dates.map((d) => _formatDate(d)).toList(),
        }),
      ).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'unblocked_count': data['unblocked_count'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('❌ Error unblocking dates: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }

    return {
      'success': false,
      'message': 'Failed to unblock dates',
    };
  }

  /// Block date range
  Future<Map<String, dynamic>> blockDateRange({
    required int ownerId,
    required int vehicleId,
    required String vehicleType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    // Generate list of dates in the range
    List<DateTime> dateRange = [];
    DateTime current = startDate;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dateRange.add(current);
      current = current.add(const Duration(days: 1));
    }

    return await blockDates(
      ownerId: ownerId,
      vehicleId: vehicleId,
      vehicleType: vehicleType,
      dates: dateRange,
      reason: reason,
    );
  }

  /// Get availability statistics
  Future<Map<String, dynamic>> getAvailabilityStats({
    required int vehicleId,
    required String vehicleType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await getBlockedDates(
      vehicleId: vehicleId,
      vehicleType: vehicleType,
      startDate: startDate,
      endDate: endDate,
    );

    if (result['success']) {
      final blockedDates = result['blocked_dates'] as Set<DateTime>;
      final bookedDates = result['booked_dates'] as Set<DateTime>;
      
      // Calculate total days in range
      final totalDays = endDate.difference(startDate).inDays + 1;
      final availableDays = totalDays - blockedDates.length - bookedDates.length;
      
      return {
        'total_days': totalDays,
        'available_days': availableDays > 0 ? availableDays : 0,
        'blocked_days': blockedDates.length,
        'booked_days': bookedDates.length,
        'utilization_rate': totalDays > 0 
            ? ((bookedDates.length / totalDays) * 100).toStringAsFixed(1) 
            : '0.0',
      };
    }

    return {
      'total_days': 0,
      'available_days': 0,
      'blocked_days': 0,
      'booked_days': 0,
      'utilization_rate': '0.0',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
