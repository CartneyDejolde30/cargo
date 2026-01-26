// lib/USERS-UI/Owner/services/gps_tracking_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../mycar/api_config.dart';

class GpsTrackingService {
  // Fetch latest GPS location for a booking
  Future<Map<String, dynamic>?> fetchCurrentLocation(String bookingId) async {
    try {
      debugPrint('📍 Fetching current location for booking: $bookingId');
      
      final url = Uri.parse(
        '${ApiConfig.getCurrentLocationEndpoint}?booking_id=$bookingId'
      );
      
      debugPrint('🌐 URL: $url');
      
      final response = await http.get(url).timeout(
        ApiConfig.gpsTimeout,
        onTimeout: () {
          throw TimeoutException('GPS location request timed out');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['location'] != null) {
          final location = data['location'];
          
          debugPrint('✅ Location found: ${location['latitude']}, ${location['longitude']}');
          
          return {
            'latitude': double.parse(location['latitude'].toString()),
            'longitude': double.parse(location['longitude'].toString()),
            'timestamp': location['timestamp'],
            'speed': double.tryParse(location['speed']?.toString() ?? '0') ?? 0.0,
            'accuracy': double.tryParse(location['accuracy']?.toString() ?? '0') ?? 0.0,
          };
        } else {
          debugPrint('⚠️ No location data: ${data['message']}');
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
      }
      
      return null;
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching GPS location: $e');
      return null;
    }
  }

  // Fetch location history for a booking
  Future<List<Map<String, dynamic>>> fetchLocationHistory(
    String bookingId, {
    String timeRange = 'all',
    int limit = 100,
  }) async {
    try {
      debugPrint('📊 Fetching location history for booking: $bookingId');
      debugPrint('   Time range: $timeRange, Limit: $limit');
      
      // Use debug endpoint for better error reporting
      final url = Uri.parse(
        '${ApiConfig.getLocationHistoryDebugEndpoint}'
        '?booking_id=$bookingId&time_range=$timeRange&limit=$limit'
      );
      
      debugPrint('🌐 URL: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location history request timed out');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('📦 Response data: ${json.encode(data)}');
        
        if (data['success'] == true && data['history'] != null) {
          final history = List<Map<String, dynamic>>.from(
            (data['history'] as List).map((item) => {
              'latitude': double.parse(item['latitude'].toString()),
              'longitude': double.parse(item['longitude'].toString()),
              'timestamp': item['timestamp'],
              'speed': double.tryParse(item['speed']?.toString() ?? '0') ?? 0.0,
              'accuracy': double.tryParse(item['accuracy']?.toString() ?? '0') ?? 0.0,
            })
          );
          
          debugPrint('✅ Found ${history.length} location points');
          return history;
        } else {
          debugPrint('⚠️ No history data: ${data['message']}');
          debugPrint('   Debug info: ${data['debug']}');
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
      }
      
      return [];
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout: $e');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching location history: $e');
      return [];
    }
  }

  // Check if GPS data exists for a booking
  Future<bool> hasGpsData(String bookingId) async {
    final location = await fetchCurrentLocation(bookingId);
    return location != null;
  }

  // Get GPS statistics for a booking
  Future<Map<String, dynamic>> getGpsStats(String bookingId) async {
    try {
      final history = await fetchLocationHistory(bookingId);
      
      if (history.isEmpty) {
        return {
          'total_points': 0,
          'max_speed': 0.0,
          'avg_speed': 0.0,
          'distance': 0.0,
        };
      }

      double maxSpeed = 0.0;
      double totalSpeed = 0.0;
      int speedCount = 0;

      for (var point in history) {
        final speed = point['speed'] as double;
        if (speed > maxSpeed) maxSpeed = speed;
        if (speed > 0) {
          totalSpeed += speed;
          speedCount++;
        }
      }

      return {
        'total_points': history.length,
        'max_speed': maxSpeed,
        'avg_speed': speedCount > 0 ? totalSpeed / speedCount : 0.0,
        'distance': _calculateTotalDistance(history),
      };
    } catch (e) {
      debugPrint('❌ Error calculating GPS stats: $e');
      return {
        'total_points': 0,
        'max_speed': 0.0,
        'avg_speed': 0.0,
        'distance': 0.0,
      };
    }
  }

  // Calculate total distance traveled (in km)
  double _calculateTotalDistance(List<Map<String, dynamic>> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    
    for (int i = 0; i < points.length - 1; i++) {
      final lat1 = points[i]['latitude'] as double;
      final lon1 = points[i]['longitude'] as double;
      final lat2 = points[i + 1]['latitude'] as double;
      final lon2 = points[i + 1]['longitude'] as double;
      
      totalDistance += _haversineDistance(lat1, lon1, lat2, lon2);
    }

    return totalDistance;
  }

  // Haversine formula for calculating distance between two GPS points
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
}