import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// GPS-based distance calculator service
/// Calculates distance traveled using GPS coordinates
class GpsDistanceCalculator {
  static const String _apiUrl = "http://10.218.197.49/carGOAdmin/api/mileage/update_gps_distance.php";
  
  Position? _lastPosition;
  double _totalDistance = 0.0; // in kilometers
  int _bookingId = 0;
  bool _isTracking = false;
  
  // Minimum distance to consider as movement (in meters)
  static const double _minMovementThreshold = 10.0; // 10 meters
  
  // Maximum speed threshold (in km/h) to filter out GPS errors
  static const double _maxSpeedThreshold = 200.0; // 200 km/h

  /// Start tracking distance for a booking
  Future<void> startTracking(int bookingId) async {
    _bookingId = bookingId;
    _isTracking = true;
    _totalDistance = 0.0;
    _lastPosition = null;
    
    print("📍 GPS Distance Tracking Started for Booking #$bookingId");
  }

  /// Stop tracking distance
  void stopTracking() {
    _isTracking = false;
    _lastPosition = null;
    print("📍 GPS Distance Tracking Stopped. Total: ${_totalDistance.toStringAsFixed(2)} km");
  }

  /// Update position and calculate distance
  /// Call this method whenever you get a new GPS position
  Future<Map<String, dynamic>> updatePosition(Position newPosition) async {
    if (!_isTracking) {
      return {
        'success': false,
        'message': 'Tracking not started',
      };
    }

    // If this is the first position, just store it
    if (_lastPosition == null) {
      _lastPosition = newPosition;
      
      // Send to backend to initialize
      await _sendToBackend(newPosition.latitude, newPosition.longitude);
      
      return {
        'success': true,
        'distance_increment': 0.0,
        'total_distance': 0.0,
        'message': 'Initial position recorded',
      };
    }

    // Calculate distance from last position
    double distanceInMeters = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    double distanceInKm = distanceInMeters / 1000.0;

    // Filter out GPS errors by checking speed
    double timeElapsedSeconds = newPosition.timestamp.difference(_lastPosition!.timestamp).inSeconds.toDouble();
    if (timeElapsedSeconds > 0) {
      double speed = (distanceInKm / timeElapsedSeconds) * 3600; // km/h
      
      if (speed > _maxSpeedThreshold) {
        print("⚠️ GPS error detected: Speed ${speed.toStringAsFixed(2)} km/h exceeds threshold");
        return {
          'success': false,
          'message': 'GPS error: unrealistic speed detected',
          'total_distance': _totalDistance,
        };
      }
    }

    // Only add distance if movement is significant
    if (distanceInMeters >= _minMovementThreshold) {
      _totalDistance += distanceInKm;
      _lastPosition = newPosition;
      
      // Send to backend
      await _sendToBackend(newPosition.latitude, newPosition.longitude);
      
      print("📍 Distance updated: +${distanceInKm.toStringAsFixed(3)} km | Total: ${_totalDistance.toStringAsFixed(2)} km");
      
      return {
        'success': true,
        'distance_increment': distanceInKm,
        'total_distance': _totalDistance,
        'message': 'Distance updated',
      };
    } else {
      return {
        'success': true,
        'distance_increment': 0.0,
        'total_distance': _totalDistance,
        'message': 'Movement too small to track',
      };
    }
  }

  /// Send GPS update to backend
  Future<void> _sendToBackend(double latitude, double longitude) async {
    if (_bookingId == 0) return;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'booking_id': _bookingId.toString(),
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print("✅ GPS data synced to server: ${data['message']}");
        }
      }
    } catch (e) {
      print("❌ Error sending GPS data to backend: $e");
    }
  }

  /// Get current total distance
  double getTotalDistance() {
    return _totalDistance;
  }

  /// Check if tracking is active
  bool isTracking() {
    return _isTracking;
  }

  /// Calculate distance between two coordinates (static utility)
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    double distanceInMeters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distanceInMeters / 1000.0; // Convert to kilometers
  }

  /// Calculate distance using Haversine formula (alternative method)
  static double haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in km
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Calculate total distance from a list of waypoints
  static double calculateTotalDistanceFromWaypoints(List<Position> waypoints) {
    if (waypoints.length < 2) return 0.0;

    double totalDistance = 0.0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      double distance = calculateDistance(
        lat1: waypoints[i].latitude,
        lon1: waypoints[i].longitude,
        lat2: waypoints[i + 1].latitude,
        lon2: waypoints[i + 1].longitude,
      );
      totalDistance += distance;
    }

    return totalDistance;
  }

  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return "${(distanceInKm * 1000).toStringAsFixed(0)} m";
    } else {
      return "${distanceInKm.toStringAsFixed(2)} km";
    }
  }

  /// Get distance status (useful for UI)
  Map<String, dynamic> getDistanceStatus({
    required double allowedMileage,
    required bool hasUnlimitedMileage,
  }) {
    if (hasUnlimitedMileage) {
      return {
        'status': 'unlimited',
        'message': 'Unlimited mileage',
        'remaining': null,
        'percentage': 0.0,
        'color': 'green',
      };
    }

    if (allowedMileage == 0) {
      return {
        'status': 'no_limit',
        'message': 'No limit set',
        'remaining': null,
        'percentage': 0.0,
        'color': 'green',
      };
    }

    double remaining = allowedMileage - _totalDistance;
    double percentage = (_totalDistance / allowedMileage) * 100;

    String status;
    String message;
    String color;

    if (percentage < 70) {
      status = 'safe';
      message = 'Within limit';
      color = 'green';
    } else if (percentage < 90) {
      status = 'warning';
      message = 'Approaching limit';
      color = 'orange';
    } else if (percentage < 100) {
      status = 'critical';
      message = 'Near limit!';
      color = 'red';
    } else {
      status = 'exceeded';
      message = 'Limit exceeded';
      color = 'red';
    }

    return {
      'status': status,
      'message': message,
      'remaining': remaining,
      'percentage': percentage,
      'color': color,
      'used': _totalDistance,
      'allowed': allowedMileage,
    };
  }

  /// Reset tracking data
  void reset() {
    _totalDistance = 0.0;
    _lastPosition = null;
    _isTracking = false;
    _bookingId = 0;
  }
}
