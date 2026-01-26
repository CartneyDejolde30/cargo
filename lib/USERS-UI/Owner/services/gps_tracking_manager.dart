// lib/USERS-UI/Owner/services/gps_tracking_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../mycar/api_config.dart';

/// Singleton GPS tracking manager to prevent multiple instances
class GpsTrackingManager {
  static final GpsTrackingManager _instance = GpsTrackingManager._internal();
  factory GpsTrackingManager() => _instance;
  GpsTrackingManager._internal();

  // Track which bookings are currently being tracked
  final Map<String, StreamSubscription<Position>?> _activeTrackers = {};
  final Map<String, bool> _isInitializing = {};
  
  // Prevent rapid consecutive starts
  final Map<String, DateTime> _lastStartAttempt = {};
  static const Duration _minStartInterval = Duration(seconds: 5);

  /// Check if a booking is currently being tracked
  bool isTracking(String bookingId) {
    return _activeTrackers.containsKey(bookingId) && 
           _activeTrackers[bookingId] != null;
  }

  /// Check if a booking is currently initializing
  bool isInitializing(String bookingId) {
    return _isInitializing[bookingId] == true;
  }

  /// Start GPS tracking for a booking
  Future<bool> startTracking(String bookingId) async {
    // Prevent rapid consecutive starts
    final lastAttempt = _lastStartAttempt[bookingId];
    if (lastAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
      if (timeSinceLastAttempt < _minStartInterval) {
        debugPrint('⏸️ Ignoring start request - too soon after last attempt');
        return isTracking(bookingId);
      }
    }
    _lastStartAttempt[bookingId] = DateTime.now();

    // Check if already tracking
    if (isTracking(bookingId)) {
      debugPrint('ℹ️ Already tracking booking $bookingId');
      return true;
    }

    // Check if currently initializing
    if (isInitializing(bookingId)) {
      debugPrint('⏳ Already initializing tracking for booking $bookingId');
      return false;
    }

    try {
      _isInitializing[bookingId] = true;
      debugPrint('🚀 Starting GPS tracking for booking: $bookingId');

      // Check permissions
      final permission = await Geolocator.checkPermission();
      debugPrint('📋 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || 
            requested == LocationPermission.deniedForever) {
          debugPrint('❌ Location permission denied');
          _isInitializing[bookingId] = false;
          return false;
        }
      }

      debugPrint('✅ Location permission granted');

      // Get initial position
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Getting initial position timed out');
          },
        );

        debugPrint('√ Initial position obtained:');
        debugPrint('   Lat: ${position.latitude}');
        debugPrint('   Lng: ${position.longitude}');
        
        // Send initial location
        await _sendLocationUpdate(bookingId, position);
      } catch (e) {
        debugPrint('⚠️ Could not get initial position: $e');
        // Continue anyway - will get position from stream
      }

      // Start position stream with proper settings from config
      final LocationSettings locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: ApiConfig.minDistanceFilter.toInt(),
        intervalDuration: ApiConfig.locationUpdateInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "CarGO is tracking your rental location",
          notificationTitle: "Location Tracking Active",
          enableWakeLock: true,
        ),
      );

      final positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );

      // Subscribe to position updates
      _activeTrackers[bookingId] = positionStream.listen(
        (Position position) {
          _sendLocationUpdate(bookingId, position);
        },
        onError: (error) {
          debugPrint('❌ Position stream error: $error');
        },
        cancelOnError: false,
      );

      _isInitializing[bookingId] = false;
      debugPrint('✅ GPS tracking started successfully for booking $bookingId');
      return true;

    } catch (e) {
      debugPrint('❌ Error starting GPS tracking: $e');
      _isInitializing[bookingId] = false;
      return false;
    }
  }

  /// Stop GPS tracking for a booking
  Future<void> stopTracking(String bookingId) async {
    debugPrint('🛑 Stopping GPS tracking for booking: $bookingId');
    
    final subscription = _activeTrackers[bookingId];
    if (subscription != null) {
      await subscription.cancel();
      _activeTrackers.remove(bookingId);
      debugPrint('✅ GPS tracking stopped for booking $bookingId');
    } else {
      debugPrint('ℹ️ No active tracking found for booking $bookingId');
    }

    _isInitializing.remove(bookingId);
    _lastStartAttempt.remove(bookingId);
  }

  /// Stop all GPS tracking
  Future<void> stopAllTracking() async {
    debugPrint('🛑 Stopping all GPS tracking');
    
    final bookingIds = _activeTrackers.keys.toList();
    for (final bookingId in bookingIds) {
      await stopTracking(bookingId);
    }
    
    _isInitializing.clear();
    _lastStartAttempt.clear();
  }

  /// Send location update to server
  Future<void> _sendLocationUpdate(String bookingId, Position position) async {
    try {
      debugPrint('📡 Sending location update for booking $bookingId...');
      debugPrint('   Lat: ${position.latitude}');
      debugPrint('   Lng: ${position.longitude}');
      debugPrint('   Speed: ${(position.speed * 3.6).toStringAsFixed(2)} km/h');
      debugPrint('   Accuracy: ${position.accuracy.toStringAsFixed(2)}m');

      final url = Uri.parse('${ApiConfig.updateLocationEndpoint}');
      
      final payload = {
        'booking_id': bookingId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed * 3.6, // Convert m/s to km/h
        'accuracy': position.accuracy,
      };

      debugPrint('📤 Sending to: $url');
      debugPrint('📦 Payload: ${json.encode(payload)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(
        ApiConfig.gpsTimeout,
        onTimeout: () {
          throw TimeoutException('Location update request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Location update sent successfully');
        } else {
          debugPrint('⚠️ Server responded with error: ${data['message']}');
        }
      } else {
        debugPrint('❌ HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending location update: $e');
      // Don't throw - just log and continue
    }
  }

  /// Get current tracking status
  Map<String, dynamic> getTrackingStatus() {
    return {
      'active_bookings': _activeTrackers.keys.toList(),
      'initializing_bookings': _isInitializing.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      'total_active': _activeTrackers.length,
    };
  }

  /// Dispose of the manager (call on app termination)
  Future<void> dispose() async {
    await stopAllTracking();
  }
}