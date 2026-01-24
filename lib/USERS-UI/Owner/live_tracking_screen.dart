import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'services/gps_tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String carName;
  final String renterName;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
    required this.carName,
    required this.renterName,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const String _mapTilerKey = 'YGJxmPnRtlTHI1endzDH';
  
  final MapController _mapController = MapController();
  final GpsTrackingService _trackingService = GpsTrackingService();
  
  Timer? _updateTimer;
  LatLng? _currentLocation;
  List<LatLng> _locationHistory = [];
  String? _lastUpdate;
  double? _currentSpeed;
  bool _isLoading = true;
  bool _isTracking = true;
  
  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  void _startTracking() {
    _fetchCurrentLocation();
    _fetchLocationHistory();
    
    // Update every 10 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isTracking) {
        _fetchCurrentLocation();
      }
    });
  }

  void _stopTracking() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _fetchCurrentLocation() async {
    final location = await _trackingService.fetchCurrentLocation(widget.bookingId);
    
    if (location != null && mounted) {
      setState(() {
        _currentLocation = LatLng(location['latitude'], location['longitude']);
        _lastUpdate = _formatTimestamp(location['timestamp']);
        _currentSpeed = location['speed'];
        _isLoading = false;
        
        // Add to history
        if (_currentLocation != null) {
          _locationHistory.add(_currentLocation!);
          // Keep only last 50 points
          if (_locationHistory.length > 50) {
            _locationHistory.removeAt(0);
          }
        }
      });

      // Center map on first load
      if (_locationHistory.length == 1) {
        _centerOnCar();
      }
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocationHistory() async {
    final history = await _trackingService.fetchLocationHistory(widget.bookingId);
    
    if (history.isNotEmpty && mounted) {
      setState(() {
        _locationHistory = history.map((loc) => 
          LatLng(loc['latitude'], loc['longitude'])
        ).toList();
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _centerOnCar() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  void _toggleTracking() {
    setState(() => _isTracking = !_isTracking);
    
    if (_isTracking) {
      _startTracking();
    } else {
      _stopTracking();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTracking ? 'Live tracking enabled' : 'Live tracking paused',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: _isTracking ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          _buildBottomCard(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? const LatLng(14.5995, 120.9842), // Manila default
        initialZoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$_mapTilerKey',
          userAgentPackageName: 'com.yourcompany.app',
        ),
        if (_locationHistory.length > 1) _buildTrackingPath(),
        if (_currentLocation != null) _buildCarMarker(),
      ],
    );
  }

  Widget _buildTrackingPath() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: _locationHistory,
          color: Colors.blue.shade600,
          strokeWidth: 4.0,
          borderColor: Colors.white,
          borderStrokeWidth: 1.5,
          gradientColors: [
            Colors.blue.shade300,
            Colors.blue.shade700,
          ],
        ),
      ],
    );
  }

  Widget _buildCarMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _currentLocation!,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing circle animation
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              // Car icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Tracking',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.carName,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _centerOnCar,
              icon: const Icon(Icons.my_location, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rented by',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      widget.renterName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isTracking ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isTracking ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isTracking ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTracking ? 'Live' : 'Paused',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isTracking ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.speed,
                      'Speed',
                      _currentSpeed != null ? '${_currentSpeed!.toStringAsFixed(1)} km/h' : '--',
                      Colors.blue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.update,
                      'Last Update',
                      _lastUpdate ?? '--',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleTracking,
                    icon: Icon(
                      _isTracking ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      _isTracking ? 'Pause' : 'Resume',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _centerOnCar,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(
                      'Center',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 16),
              Text(
                'Loading location...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}