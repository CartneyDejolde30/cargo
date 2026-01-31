import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../mycar/api_constants.dart';
import 'analytics_models.dart';

/// Enhanced Analytics Service
class AnalyticsService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get overview statistics
  Future<AnalyticsOverview?> getOverviewStats({int? ownerId}) async {
    try {
      final url = ownerId != null
          ? '$_baseUrl/api/analytics/get_analytics_data.php?type=overview&owner_id=$ownerId'
          : '$_baseUrl/api/analytics/get_analytics_data.php?type=overview';

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return AnalyticsOverview.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching overview stats: $e');
    }
    return null;
  }

  /// Get booking trends (last 6 months)
  Future<List<BookingTrend>> getBookingTrends({int? ownerId}) async {
    try {
      final url = ownerId != null
          ? '$_baseUrl/api/analytics/get_analytics_data.php?type=booking_trends&owner_id=$ownerId'
          : '$_baseUrl/api/analytics/get_analytics_data.php?type=booking_trends';

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['trends'] is List) {
          return (data['trends'] as List)
              .map((trend) => BookingTrend.fromJson(trend))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching booking trends: $e');
    }
    return [];
  }

  /// Get revenue breakdown by vehicle type and payment status
  Future<RevenueBreakdown?> getRevenueBreakdown({int? ownerId}) async {
    try {
      final url = ownerId != null
          ? '$_baseUrl/api/analytics/get_analytics_data.php?type=revenue_breakdown&owner_id=$ownerId'
          : '$_baseUrl/api/analytics/get_analytics_data.php?type=revenue_breakdown';

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return RevenueBreakdown.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching revenue breakdown: $e');
    }
    return null;
  }

  /// Get popular vehicles
  Future<PopularVehicles?> getPopularVehicles({int? ownerId}) async {
    try {
      final url = ownerId != null
          ? '$_baseUrl/api/analytics/get_analytics_data.php?type=popular_vehicles&owner_id=$ownerId'
          : '$_baseUrl/api/analytics/get_analytics_data.php?type=popular_vehicles';

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return PopularVehicles.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching popular vehicles: $e');
    }
    return null;
  }

  /// Get peak booking hours and days
  Future<PeakBookingData?> getPeakBookingHours({int? ownerId}) async {
    try {
      final url = ownerId != null
          ? '$_baseUrl/api/analytics/get_analytics_data.php?type=peak_hours&owner_id=$ownerId'
          : '$_baseUrl/api/analytics/get_analytics_data.php?type=peak_hours';

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return PeakBookingData.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching peak booking hours: $e');
    }
    return null;
  }

  /// Get comprehensive analytics data
  Future<Map<String, dynamic>> getComprehensiveAnalytics({int? ownerId}) async {
    final results = await Future.wait([
      getOverviewStats(ownerId: ownerId),
      getBookingTrends(ownerId: ownerId),
      getRevenueBreakdown(ownerId: ownerId),
      getPopularVehicles(ownerId: ownerId),
      getPeakBookingHours(ownerId: ownerId),
    ]);

    return {
      'overview': results[0],
      'booking_trends': results[1],
      'revenue_breakdown': results[2],
      'popular_vehicles': results[3],
      'peak_hours': results[4],
    };
  }
}
