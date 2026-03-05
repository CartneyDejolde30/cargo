import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cargo/config/maptiler_config.dart';
import 'package:cargo/config/api_config.dart';
import 'package:cargo/widgets/map_controls.dart';
import 'package:cargo/widgets/map_style_switcher.dart';
import 'package:cargo/USERS-UI/widgets/location_permission_helper.dart';
import 'motorcycle_detail_screen.dart';

class MotorcyclesMapViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> motorcycles;
  final String title;

  const MotorcyclesMapViewScreen({
    super.key,
    required this.motorcycles,
    this.title = 'Map View',
  });

  @override
  State<MotorcyclesMapViewScreen> createState() => _MotorcyclesMapViewScreenState();
}

class _MotorcyclesMapViewScreenState extends State<MotorcyclesMapViewScreen> {
  final MapController _mapController = MapController();
  String _currentMapStyle = MapTilerConfig.defaultStyle;
  bool _showStyleSwitcher = false;
  Map<String, dynamic>? _selectedMotorcycle;
  
  List<Marker> _markers = [];
  LatLng _center = LatLng(8.7167, 125.7500); // Bayugan, Agusan del Sur
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
    _calculateCenter();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check and request permissions
      final hasPermission = await LocationPermissionHelper.showPermissionDialog(context);
      
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location permission is required to show your location',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        // Animate to user location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15,
        );

        // Rebuild markers to include user location
        _buildMarkers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Location updated',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to get location: ${e.toString()}',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _buildMarkers() {
    List<Marker> motorcycleMarkers = widget.motorcycles.where((motorcycle) {
      return motorcycle['latitude'] != null && 
             motorcycle['longitude'] != null &&
             motorcycle['latitude'] != 0 &&
             motorcycle['longitude'] != 0;
    }).map((motorcycle) {
      final lat = double.tryParse(motorcycle['latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(motorcycle['longitude'].toString()) ?? 0.0;
      
      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 75,
        child: GestureDetector(
          onTap: () => _showMotorcycleDetails(motorcycle),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Custom marker
              Positioned(
                top: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedMotorcycle?['id'] == motorcycle['id']
                        ? Theme.of(context).primaryColor
                        : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.two_wheeler,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Price badge
              if (motorcycle['price'] != null)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedMotorcycle?['id'] == motorcycle['id']
                            ? Theme.of(context).primaryColor
                            : Colors.red,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '₱${motorcycle['price']}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();

    // Add user location marker if available
    if (_currentPosition != null) {
      motorcycleMarkers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              // Inner circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              // Center dot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    _markers = motorcycleMarkers;
  }

  void _calculateCenter() {
    if (_markers.isEmpty) return;
    
    double totalLat = 0;
    double totalLng = 0;
    
    for (var marker in _markers) {
      totalLat += marker.point.latitude;
      totalLng += marker.point.longitude;
    }
    
    setState(() {
      _center = LatLng(
        totalLat / _markers.length,
        totalLng / _markers.length,
      );
    });
  }

  void _showMotorcycleDetails(Map<String, dynamic> motorcycle) {
    setState(() {
      _selectedMotorcycle = motorcycle;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _getImageUrl(motorcycle['image']),
                    width: 100,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.two_wheeler, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${motorcycle['brand']} ${motorcycle['model']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${motorcycle['price']}/day',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${motorcycle['rating'] ?? 0.0}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MotorcycleDetailScreen(
                      motorcycleId: int.tryParse(motorcycle['id'].toString()) ?? 0,
                      motorcycleName: '${motorcycle['brand']} ${motorcycle['model']}',
                      motorcycleImage: _getImageUrl(motorcycle['image']),
                      price: motorcycle['price'].toString(),
                      rating: double.tryParse(motorcycle['rating'].toString()) ?? 0.0,
                      location: motorcycle['location'] ?? 'Unknown',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'View Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() {
        _selectedMotorcycle = null;
      });
    });
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "https://via.placeholder.com/300";
    }
    return GlobalApiConfig.getImageUrl(path.replaceFirst("uploads/", ""));
  }

  void _changeMapStyle(String style) {
    setState(() {
      _currentMapStyle = style;
      _showStyleSwitcher = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2C3E50),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.two_wheeler,
                      size: 16,
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2C3E50),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.motorcycles.length}',
                      style: GoogleFonts.poppins(
                        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2C3E50),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _markers.length == 1 ? 15 : 12,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: MapTilerConfig.getTileUrl(_currentMapStyle),
                userAgentPackageName: 'com.example.flutter_application_1',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          
          Positioned(
            top: 16,
            right: 16,
            child: MapControls(
              mapController: _mapController,
              onCenterLocation: _getCurrentLocation,
            ),
          ),

          // Loading indicator when getting location
          if (_isLoadingLocation)
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          
          if (_showStyleSwitcher)
            Positioned(
              top: 220,
              right: 16,
              child: MapStyleSwitcher(
                currentStyle: _currentMapStyle,
                onStyleChanged: _changeMapStyle,
              ),
            ),
          
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.motorcycles.length} Motorcycles',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap markers to view details',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.two_wheeler,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
