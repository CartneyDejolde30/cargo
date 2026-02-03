import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../Owner/mycar/api_constants.dart';
import './dashboard_stats.dart';

class DashboardService {
  /* ---------------- FETCH DASHBOARD STATS ---------------- */
  Future<DashboardStats> fetchDashboardStats(String ownerId) async {
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/api/dashboard/dashboard_stats.php?owner_id=$ownerId",
      );

      debugPrint("📡 Dashboard API: $url");

      final response =
          await http.get(url).timeout(ApiConstants.apiTimeout);

      debugPrint("📥 Dashboard Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['stats'] != null) {
          // ✅ DEBUG: Log the exact values received
          debugPrint("🔍 Total Cars from API: ${data['stats']['total_cars']}");
          debugPrint("🔍 Approved Cars from API: ${data['stats']['approved_cars']}");
          debugPrint("🔍 Pending Cars from API: ${data['stats']['pending_cars']}");
          debugPrint("🔍 Rented Cars from API: ${data['stats']['rented_cars']}");
          
          final stats = DashboardStats.fromJson(
            Map<String, dynamic>.from(data['stats']),
          );
          
          // ✅ DEBUG: Log the parsed values
          debugPrint("✅ Parsed Total Cars: ${stats.totalCars}");
          debugPrint("✅ Parsed Approved Cars: ${stats.approvedCars}");
          
          return stats;
        } else {
          debugPrint("❌ Dashboard stats error: ${data['message']}");
        }
      } else {
        debugPrint("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching dashboard stats: $e");
    }

    return DashboardStats.empty();
  }

  /* ---------------- FETCH REVENUE TREND (For Chart) ---------------- */
  Future<List<Map<String, dynamic>>> fetchRevenueTrend(
    String ownerId, {
    String period = 'week',
  }) async {
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/api/revenue_trend.php"
        "?owner_id=$ownerId&period=$period",
      );

      debugPrint("📡 Revenue trend API: $url");

      final response =
          await http.get(url).timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['trend'] is List) {
          return List<Map<String, dynamic>>.from(data['trend']);
        }
      } else {
        debugPrint("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching revenue trend: $e");
    }

    return [];
  }
}
