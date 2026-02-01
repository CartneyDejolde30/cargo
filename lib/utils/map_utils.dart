import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';

/// Map Utilities
/// Helper functions for map-related calculations
class MapUtils {
  static const Distance _distance = Distance();
  
  /// Calculate distance between two points in meters
  static double calculateDistance(LatLng start, LatLng end) {
    return _distance.as(
      LengthUnit.Meter,
      start,
      end,
    );
  }
  
  /// Calculate distance from Position to LatLng
  static double calculateDistanceFromPosition(Position position, LatLng destination) {
    return calculateDistance(
      LatLng(position.latitude, position.longitude),
      destination,
    );
  }
  
  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
  
  /// Calculate ETA based on distance and average speed
  /// Returns duration
  static Duration calculateETA(double distanceMeters, {double speedKmh = 40.0}) {
    final distanceKm = distanceMeters / 1000;
    final hours = distanceKm / speedKmh;
    final minutes = (hours * 60).round();
    return Duration(minutes: minutes);
  }
  
  /// Format ETA for display
  static String formatETA(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
  
  /// Calculate bearing between two points (in degrees)
  static double calculateBearing(LatLng start, LatLng end) {
    return _distance.bearing(start, end);
  }
  
  /// Check if a point is within radius of another point
  static bool isWithinRadius(LatLng point, LatLng center, double radiusMeters) {
    final distance = calculateDistance(point, center);
    return distance <= radiusMeters;
  }
  
  /// Get bounds that encompass all points with padding
  static LatLngBounds getBoundsForPoints(List<LatLng> points, {double paddingKm = 1.0}) {
    if (points.isEmpty) {
      return LatLngBounds(
        LatLng(0, 0),
        LatLng(0, 0),
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    // Add padding (approximate: 1 degree ≈ 111 km)
    final padding = paddingKm / 111;
    
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }
  
  /// Convert Position to LatLng
  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }
}
