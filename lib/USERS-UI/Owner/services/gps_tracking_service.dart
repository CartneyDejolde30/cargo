// lib/USERS-UI/Owner/services/gps_tracking_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../mycar/api_config.dart';

// Top-level function for isolate execution
Future<Map<String, dynamic>?> _fetchLocationInIsolate(Map<String, dynamic> params) async {
  try {
    final url = Uri.parse(params['url'] as String);
    final timeout = Duration(seconds: params['timeout'] as int);
    
    final response = await http.get(url).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('GPS location request timed out');
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true && data['location'] != null) {
        final location = data['location'];
        
        return {
          'latitude': double.parse(location['latitude'].toString()),
          'longitude': double.parse(location['longitude'].toString()),
          'timestamp': location['timestamp'],
          'speed': double.tryParse(location['speed']?.toString() ?? '0') ?? 0.0,
          'accuracy': double.tryParse(location['accuracy']?.toString() ?? '0') ?? 0.0,
        };
      }
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

// Top-level function for history fetch in isolate
Future<List<Map<String, dynamic>>> _fetchHistoryInIsolate(Map<String, dynamic> params) async {
  try {
    final url = Uri.parse(params['url'] as String);
    final timeout = Duration(seconds: params['timeout'] as int);
    
    final response = await http.get(url).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('Location history request timed out');
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true && data['history'] != null) {
        return List<Map<String, dynamic>>.from(
          (data['history'] as List).map((item) => {
            'latitude': double.parse(item['latitude'].toString()),
            'longitude': double.parse(item['longitude'].toString()),
            'timestamp': item['timestamp'],
            'speed': double.tryParse(item['speed']?.toString() ?? '0') ?? 0.0,
            'accuracy': double.tryParse(item['accuracy']?.toString() ?? '0') ?? 0.0,
          })
        );
      }
    }
    
    return [];
  } catch (e) {
    return [];
  }
}

class GpsTrackingService {
  // Cache for recent location data
  final Map<String, Map<String, dynamic>?> _locationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(seconds: 5);
  
  // Fetch latest GPS location for a booking
  Future<Map<String, dynamic>?> fetchCurrentLocation(String bookingId) async {
    try {
      // Check cache first
      if (_locationCache.containsKey(bookingId)) {
        final cacheTime = _cacheTimestamps[bookingId];
        if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheDuration) {
          debugPrint('📦 Using cached location for booking: $bookingId');
          return _locationCache[bookingId];
        }
      }
      
      debugPrint('📍 Fetching current location for booking: $bookingId');
      
      final url = '${ApiConfig.getCurrentLocationEndpoint}?booking_id=$bookingId';
      debugPrint('🌐 URL: $url');
      
      // Run in background isolate to avoid blocking main thread
      final result = await compute(_fetchLocationInIsolate, {
        'url': url,
        'timeout': 10,
      });

      // Update cache
      _locationCache[bookingId] = result;
      _cacheTimestamps[bookingId] = DateTime.now();

      if (result != null) {
        debugPrint('✅ Location found: ${result['latitude']}, ${result['longitude']}');
      } else {
        debugPrint('⚠️ No location data available');
      }
      
      return result;
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
      final url = '${ApiConfig.getLocationHistoryDebugEndpoint}'
          '?booking_id=$bookingId&time_range=$timeRange&limit=$limit';
      
      debugPrint('🌐 URL: $url');
      
      // Run in background isolate to avoid blocking main thread
      final history = await compute(_fetchHistoryInIsolate, {
        'url': url,
        'timeout': 15,
      });
      
      debugPrint('✅ Found ${history.length} location points');
      return history;
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