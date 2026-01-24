
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../Owner/mycar/api_config.dart';

class RenterGpsService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const Duration _updateInterval = Duration(seconds: 30); // Update every 30 seconds
  
  Timer? _locationTimer;
  String? _activeBookingId;
  bool _isTracking = false;

  // Start tracking for an active booking
  Future<void> startTracking(String bookingId) async {
    if (_isTracking && _activeBookingId == bookingId) {
      debugPrint('⚠️ Already tracking booking: $bookingId');
      return;
    }

    _activeBookingId = bookingId;
    _isTracking = true;

    debugPrint('✅ Started GPS tracking for booking: $bookingId');

    // Send initial location
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
    _activeBookingId = null;
    debugPrint('🛑 Stopped GPS tracking');
  }

  // Send location update to server
  Future<void> _sendLocationUpdate() async {
    if (_activeBookingId == null) return;

    try {
      // Check and request location permission
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        debugPrint('❌ Location permission denied');
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only update if moved 10 meters
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timeout');
        },
      );

      // Send to server
      final url = Uri.parse('$_baseUrl/update_location.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': _activeBookingId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed * 3.6, // Convert m/s to km/h
          'accuracy': position.accuracy,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
        } else {
          debugPrint('⚠️ Location update failed: ${data['message']}');
        }
      } else {
        debugPrint('❌ Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error sending location: $e');
    }
  }

  // Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
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
    try {
      await _sendLocationUpdate();
      return true;
    } catch (e) {
      debugPrint('❌ Manual update failed: $e');
      return false;
    }
  }

  // Check if currently tracking
  bool get isTracking => _isTracking;
  String? get activeBookingId => _activeBookingId;

  // Cleanup
  void dispose() {
    stopTracking();
  }
}

// ========================================
// SINGLETON INSTANCE (Global access)
// ========================================
final renterGpsService = RenterGpsService();

// ========================================
// USAGE IN RENTER'S ACTIVE BOOKING PAGE
// Add this to lib/USERS-UI/Renter/bookings/active_booking_screen.dart
// ========================================

/*
INTEGRATION EXAMPLE:

import 'package:flutter/material.dart';
import '../services/renter_gps_service.dart';

class RenterActiveBookingScreen extends StatefulWidget {
  final String bookingId;
  
  const RenterActiveBookingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<RenterActiveBookingScreen> createState() => _RenterActiveBookingScreenState();
}

class _RenterActiveBookingScreenState extends State<RenterActiveBookingScreen> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start GPS tracking when booking screen opens
    renterGpsService.startTracking(widget.bookingId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop tracking when leaving screen
    renterGpsService.stopTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Continue tracking even when app is in background
    if (state == AppLifecycleState.paused) {
      debugPrint('App paused - GPS tracking continues');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed - GPS tracking active');
      // Restart tracking if needed
      if (!renterGpsService.isTracking) {
        renterGpsService.startTracking(widget.bookingId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Rental'),
        actions: [
          // GPS tracking indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: renterGpsService.isTracking 
                  ? Colors.green.shade100 
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gps_fixed,
                  size: 14,
                  color: renterGpsService.isTracking 
                      ? Colors.green.shade700 
                      : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  renterGpsService.isTracking ? 'Tracking' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: renterGpsService.isTracking 
                        ? Colors.green.shade700 
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your booking details here
            
            const SizedBox(height: 20),
            
            // Manual update button (optional)
            ElevatedButton.icon(
              onPressed: () async {
                final success = await renterGpsService.sendManualUpdate(widget.bookingId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location updated'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Update Location Now'),
            ),
          ],
        ),
      ),
    );
  }
}
*/