// lib/USERS-UI/services/renter_gps_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../Owner/mycar/api_config.dart';

class RenterGpsService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const Duration _updateInterval = Duration(seconds: 30);
  
  Timer? _locationTimer;
  String? _activeBookingId;
  bool _isTracking = false;
  int _successfulUpdates = 0;
  int _failedUpdates = 0;

  // Start tracking for an active booking
  Future<void> startTracking(String bookingId) async {
    if (_isTracking && _activeBookingId == bookingId) {
      debugPrint('⚠️ Already tracking booking: $bookingId');
      return;
    }

    _activeBookingId = bookingId;
    _isTracking = true;
    _successfulUpdates = 0;
    _failedUpdates = 0;

    debugPrint('✅ Started GPS tracking for booking: $bookingId');
    debugPrint('📍 Update interval: ${_updateInterval.inSeconds} seconds');

    // Send initial location immediately
    await _sendLocationUpdate();

    // Schedule periodic updates
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_updateInterval, (_) async {
      if (_isTracking) {
        await _sendLocationUpdate();
      }
    });
  }

  // Stop tracking
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    
    debugPrint('🛑 Stopped GPS tracking');
    debugPrint('📊 Session stats: $_successfulUpdates successful, $_failedUpdates failed');
    
    _activeBookingId = null;
    _successfulUpdates = 0;
    _failedUpdates = 0;
  }

  // Send location update to server
  Future<void> _sendLocationUpdate() async {
    if (_activeBookingId == null) {
      debugPrint('❌ No active booking ID');
      return;
    }

    try {
      debugPrint('📡 Attempting location update for booking $_activeBookingId...');
      
      // Check and request location permission
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        debugPrint('❌ Location permission denied');
        _failedUpdates++;
        return;
      }

      debugPrint('✓ Location permission granted');

      // Get current location
      debugPrint('📍 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timeout after 15s');
        },
      );

      debugPrint('✓ Position obtained: ${position.latitude}, ${position.longitude}');
      debugPrint('  Speed: ${(position.speed * 3.6).toStringAsFixed(2)} km/h');
      debugPrint('  Accuracy: ${position.accuracy.toStringAsFixed(2)}m');

      // Prepare request
      final url = Uri.parse('$_baseUrl/GPS_tracking/update_location.php');
      final payload = {
        'booking_id': _activeBookingId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed * 3.6, // Convert m/s to km/h
        'accuracy': position.accuracy,
      };

      debugPrint('📤 Sending to: $url');
      debugPrint('📦 Payload: ${json.encode(payload)}');

      // Send to server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _successfulUpdates++;
          debugPrint('✅ Location updated successfully (#$_successfulUpdates)');
        } else {
          _failedUpdates++;
          debugPrint('⚠️ Server reported failure: ${data['message']}');
        }
      } else {
        _failedUpdates++;
        debugPrint('❌ HTTP error ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException catch (e) {
      _failedUpdates++;
      debugPrint('⏱️ Timeout: $e');
    } on PermissionDeniedException catch (e) {
      _failedUpdates++;
      debugPrint('🚫 Permission denied: $e');
    } catch (e, stackTrace) {
      _failedUpdates++;
      debugPrint('❌ Error sending location: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    debugPrint('📋 Current permission: $permission');
    
    if (permission == LocationPermission.denied) {
      debugPrint('🔐 Requesting location permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('📋 New permission: $permission');
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Location permission permanently denied');
      return false;
    }

    return permission != LocationPermission.denied;
  }

  // Manual location update (can be called on-demand)
  Future<bool> sendManualUpdate(String bookingId) async {
    _activeBookingId = bookingId;
    debugPrint('🔄 Manual update requested for booking $bookingId');
    
    try {
      await _sendLocationUpdate();
      return _successfulUpdates > 0;
    } catch (e) {
      debugPrint('❌ Manual update failed: $e');
      return false;
    }
  }

  // Check if currently tracking
  bool get isTracking => _isTracking;
  String? get activeBookingId => _activeBookingId;
  int get successCount => _successfulUpdates;
  int get failCount => _failedUpdates;

  // Cleanup
  void dispose() {
    stopTracking();
  }
}

// Singleton instance
final renterGpsService = RenterGpsService();