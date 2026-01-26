// lib/USERS-UI/services/renter_gps_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../Owner/mycar/api_config.dart';

class RenterGpsService {
  static const Duration _updateInterval = Duration(seconds: 30);
  static const Duration _locationTimeout = Duration(seconds: 15);
  
  Timer? _locationTimer;
  String? _activeBookingId;
  bool _isTracking = false;
  int _successfulUpdates = 0;
  int _failedUpdates = 0;
  DateTime? _lastSuccessfulUpdate;
  String? _lastError;

  // Singleton pattern
  static final RenterGpsService _instance = RenterGpsService._internal();
  factory RenterGpsService() => _instance;
  RenterGpsService._internal();

  // Getters
  bool get isTracking => _isTracking;
  String? get activeBookingId => _activeBookingId;
  int get successCount => _successfulUpdates;
  int get failCount => _failedUpdates;
  DateTime? get lastUpdate => _lastSuccessfulUpdate;
  String? get lastError => _lastError;

  // Start tracking for an active booking
  Future<bool> startTracking(String bookingId) async {
    if (_isTracking && _activeBookingId == bookingId) {
      debugPrint('⚠️ Already tracking booking: $bookingId');
      return true;
    }

    // Stop previous tracking if exists
    if (_isTracking) {
      stopTracking();
    }

    _activeBookingId = bookingId;
    _successfulUpdates = 0;
    _failedUpdates = 0;
    _lastError = null;

    debugPrint('🚀 Starting GPS tracking for booking: $bookingId');
    debugPrint('📍 Update interval: ${_updateInterval.inSeconds} seconds');

    // Check permissions first
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      debugPrint('❌ Location permission not granted');
      _lastError = 'Location permission denied';
      return false;
    }

    debugPrint('✅ Location permission granted');

    // Send initial location immediately
    final initialSuccess = await _sendLocationUpdate();
    
    if (!initialSuccess) {
      debugPrint('⚠️ Initial location update failed, but continuing...');
    }

    // Mark as tracking and schedule periodic updates
    _isTracking = true;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_updateInterval, (_) async {
      if (_isTracking) {
        await _sendLocationUpdate();
      }
    });

    debugPrint('✅ GPS tracking started successfully');
    return true;
  }

  // Stop tracking
  void stopTracking() {
    if (!_isTracking) {
      debugPrint('ℹ️ GPS tracking already stopped');
      return;
    }

    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    
    debugPrint('🛑 Stopped GPS tracking');
    debugPrint('📊 Session stats:');
    debugPrint('   - Successful updates: $_successfulUpdates');
    debugPrint('   - Failed updates: $_failedUpdates');
    debugPrint('   - Last update: $_lastSuccessfulUpdate');
    
    _activeBookingId = null;
    _successfulUpdates = 0;
    _failedUpdates = 0;
    _lastSuccessfulUpdate = null;
    _lastError = null;
  }

  // Send location update to server
  Future<bool> _sendLocationUpdate() async {
    if (_activeBookingId == null) {
      debugPrint('❌ No active booking ID');
      return false;
    }

    try {
      debugPrint('📡 Sending location update for booking $_activeBookingId...');
      
      // Get current location
      final position = await _getCurrentPosition();
      if (position == null) {
        _failedUpdates++;
        _lastError = 'Failed to get GPS position';
        return false;
      }

      debugPrint('✓ Position obtained:');
      debugPrint('   Lat: ${position.latitude}');
      debugPrint('   Lng: ${position.longitude}');
      debugPrint('   Speed: ${(position.speed * 3.6).toStringAsFixed(2)} km/h');
      debugPrint('   Accuracy: ${position.accuracy.toStringAsFixed(2)}m');

      // Prepare request
      final url = Uri.parse(ApiConfig.updateLocationEndpoint);
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
          _lastSuccessfulUpdate = DateTime.now();
          _lastError = null;
          debugPrint('✅ Location updated successfully (#$_successfulUpdates)');
          return true;
        } else {
          _failedUpdates++;
          _lastError = data['message'] ?? 'Server reported failure';
          debugPrint('⚠️ Server reported failure: ${data['message']}');
          return false;
        }
      } else {
        _failedUpdates++;
        _lastError = 'HTTP error ${response.statusCode}';
        debugPrint('❌ HTTP error ${response.statusCode}: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      _failedUpdates++;
      _lastError = 'Request timeout';
      debugPrint('⏱️ Timeout: $e');
      return false;
    } catch (e, stackTrace) {
      _failedUpdates++;
      _lastError = e.toString();
      debugPrint('❌ Error sending location: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Get current GPS position
  Future<Position?> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only update if moved 10m
        ),
      ).timeout(
        _locationTimeout,
        onTimeout: () {
          throw TimeoutException('GPS position timeout after ${_locationTimeout.inSeconds}s');
        },
      );

      return position;
    } on TimeoutException catch (e) {
      debugPrint('⏱️ GPS timeout: $e');
      return null;
    } on PermissionDeniedException catch (e) {
      debugPrint('🚫 Permission denied: $e');
      return null;
    } on LocationServiceDisabledException catch (e) {
      debugPrint('📍 Location services disabled: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting position: $e');
      return null;
    }
  }

  // Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        _lastError = 'Location services disabled';
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📋 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('🔐 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('📋 New permission: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        _lastError = 'Location permission permanently denied';
        return false;
      }

      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permission denied');
        _lastError = 'Location permission denied';
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      _lastError = 'Permission check failed';
      return false;
    }
  }

  // Manual location update (can be called on-demand)
  Future<bool> sendManualUpdate(String bookingId) async {
    final wasTracking = _isTracking;
    _activeBookingId = bookingId;
    
    debugPrint('🔄 Manual update requested for booking $bookingId');
    
    final success = await _sendLocationUpdate();
    
    if (!wasTracking) {
      _activeBookingId = null;
    }
    
    return success;
  }

  // Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Get tracking status summary
  Map<String, dynamic> getTrackingStatus() {
    return {
      'is_tracking': _isTracking,
      'booking_id': _activeBookingId,
      'successful_updates': _successfulUpdates,
      'failed_updates': _failedUpdates,
      'last_update': _lastSuccessfulUpdate?.toIso8601String(),
      'last_error': _lastError,
      'update_interval_seconds': _updateInterval.inSeconds,
    };
  }

  // Cleanup
  void dispose() {
    stopTracking();
  }
}

// Global singleton instance
final renterGpsService = RenterGpsService();