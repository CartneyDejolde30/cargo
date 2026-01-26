// lib/USERS-UI/widgets/location_permission_helper.dart
// Create this new file for reusable permission handling

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionHelper {
  // Check if location services and permissions are ready
  static Future<LocationPermissionStatus> checkLocationStatus() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      return LocationPermissionStatus.denied;
    }
    
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }
    
    return LocationPermissionStatus.granted;
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission != LocationPermission.denied && 
           permission != LocationPermission.deniedForever;
  }

  // Show permission dialog
  static Future<bool> showPermissionDialog(BuildContext context) async {
    final status = await checkLocationStatus();
    
    if (status == LocationPermissionStatus.granted) {
      return true;
    }

    if (!context.mounted) return false;

    if (status == LocationPermissionStatus.serviceDisabled) {
      return await _showServiceDisabledDialog(context);
    }

    if (status == LocationPermissionStatus.deniedForever) {
      return await _showPermanentlyDeniedDialog(context);
    }

    if (status == LocationPermissionStatus.denied) {
      return await _showRequestPermissionDialog(context);
    }

    return false;
  }

  static Future<bool> _showServiceDisabledDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Text('Location Services Off', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'CarGO needs location services to track your vehicle during rentals. Please enable location services in your phone settings.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              if (!context.mounted) return;
              Navigator.pop(context, false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<bool> _showPermanentlyDeniedDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Text('Permission Required', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Location permission was permanently denied. Please enable it in app settings to use GPS tracking during rentals.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              if (!context.mounted) return;
              Navigator.pop(context, false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<bool> _showRequestPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Text('Enable GPS Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CarGO needs your location to:',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildPermissionReason(Icons.security, 'Track your rented vehicle'),
            _buildPermissionReason(Icons.shield, 'Ensure safety and security'),
            _buildPermissionReason(Icons.support_agent, 'Provide support if needed'),
            const SizedBox(height: 12),
            Text(
              'Your location is only tracked during active rentals.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (result == true) {
      return await requestLocationPermission();
    }

    return false;
  }

  static Widget _buildPermissionReason(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Show GPS status indicator widget
  static Widget buildGpsStatusBadge({
    required bool isTracking,
    required int successCount,
    required int failCount,
    DateTime? lastUpdate,
  }) {
    final color = isTracking ? Colors.green : Colors.grey;
    final statusText = isTracking ? 'GPS Active' : 'GPS Inactive';
    
    String lastUpdateText = '--';
    if (lastUpdate != null) {
      final diff = DateTime.now().difference(lastUpdate);
      if (diff.inSeconds < 60) {
        lastUpdateText = '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        lastUpdateText = '${diff.inMinutes}m ago';
      } else {
        lastUpdateText = '${diff.inHours}h ago';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isTracking && lastUpdate != null)
                Text(
                  'Updated $lastUpdateText',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}