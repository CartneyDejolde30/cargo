import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../mycar/api_config.dart';

class GpsTrackingService {
  static const String _baseUrl = ApiConfig.baseUrl;
  
  // Fetch latest GPS location for a booking
  Future<Map<String, dynamic>?> fetchCurrentLocation(String bookingId) async {
    try {
      final url = Uri.parse('$_baseUrl/get_current_location.php?booking_id=$bookingId');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['location'] != null) {
          return {
            'latitude': double.parse(data['location']['latitude'].toString()),
            'longitude': double.parse(data['location']['longitude'].toString()),
            'timestamp': data['location']['timestamp'],
            'speed': data['location']['speed'] ?? 0.0,
            'accuracy': data['location']['accuracy'] ?? 0.0,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching GPS location: $e');
      return null;
    }
  }

  // Fetch location history for a booking
  Future<List<Map<String, dynamic>>> fetchLocationHistory(String bookingId) async {
    try {
      final url = Uri.parse('$_baseUrl/get_location_history.php?booking_id=$bookingId');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['history'] != null) {
          return List<Map<String, dynamic>>.from(
            (data['history'] as List).map((item) => {
              'latitude': double.parse(item['latitude'].toString()),
              'longitude': double.parse(item['longitude'].toString()),
              'timestamp': item['timestamp'],
              'speed': item['speed'] ?? 0.0,
            })
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching location history: $e');
      return [];
    }
  }
}