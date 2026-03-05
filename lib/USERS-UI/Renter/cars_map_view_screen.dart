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
import 'car_detail_screen.dart';

class CarsMapViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cars;
  final String title;

  const CarsMapViewScreen({
    super.key,
    required this.cars,
    this.title = 'Map View',
  });

  @override
  State<CarsMapViewScreen> createState() => _CarsMapViewScreenState();
}

class _CarsMapViewScreenState extends State<CarsMapViewScreen> {
  final MapController _mapController = MapController();
  String _currentMapStyle = MapTilerConfig.defaultStyle;
  bool _showStyleSwitcher = false;
  Map<String, dynamic>? _selectedCar;
  
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
    List<Marker> carMarkers = widget.cars.where((car) {
      return car['latitude'] != null && 
             car['longitude'] != null &&
             car['latitude'] != 0 &&
             car['longitude'] != 0;
    }).map((car) {
      final lat = double.tryParse(car['latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(car['longitude'].toString()) ?? 0.0;
      
      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 75,
        child: GestureDetector(
          onTap: () => _showCarDetails(car),
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
                    color: _selectedCar?['id'] == car['id']
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
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Price badge
              if (car['price'] != null)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedCar?['id'] == car['id']
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
                      '₱${car['price']}',
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
      carMarkers.add(
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

    _markers = carMarkers;
  }

  void _calculateCenter() {
    if (_markers.isEmpty) return;

    double avgLat = 0;
    double avgLng = 0;

    for (var marker in _markers) {
      avgLat += marker.point.latitude;
      avgLng += marker.point.longitude;
    }

    _center = LatLng(
      avgLat / _markers.length,
      avgLng / _markers.length,
    );
  }

  void _showCarDetails(Map<String, dynamic> car) {
    setState(() {
      _selectedCar = car;
    });

    // Animate to car location
    final lat = double.tryParse(car['latitude'].toString()) ?? 0.0;
    final lng = double.tryParse(car['longitude'].toString()) ?? 0.0;
    _mapController.move(LatLng(lat, lng), 15);
  }

  String getImageUrl(String path) {
    if (path.isEmpty) {
      return "https://via.placeholder.com/300";
    }
    return GlobalApiConfig.getImageUrl(path.replaceFirst("uploads/", ""));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      Icons.directions_car,
                      size: 16,
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2C3E50),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.cars.length}',
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
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _markers.length == 1 ? 15 : 12,
              minZoom: 8,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: MapTilerConfig.getTileUrl(_currentMapStyle),
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Map Controls (right side)
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

          // Style Switcher Button (left side, top)
          Positioned(
            top: 16,
            left: 16,
            child: Material(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showStyleSwitcher = !_showStyleSwitcher;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.layers,
                    color: Theme.of(context).iconTheme.color,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Style Switcher Panel
          if (_showStyleSwitcher)
            Positioned(
              top: 76,
              left: 16,
              child: MapStyleSwitcher(
                currentStyle: _currentMapStyle,
                onStyleChanged: (newStyle) {
                  setState(() {
                    _currentMapStyle = newStyle;
                    _showStyleSwitcher = false;
                  });
                },
              ),
            ),

          // Bottom info panel (when no car selected)
          if (_selectedCar == null && _markers.isNotEmpty)
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
                          '${widget.cars.length} Cars',
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
                      Icons.directions_car,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),

          // Car details bottom sheet
          if (_selectedCar != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCarDetailsSheet(),
            ),

          // Empty state
          if (_markers.isEmpty)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No locations available',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cars without location data cannot be shown on the map',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarDetailsSheet() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Car details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      getImageUrl(_selectedCar!['image'] ?? ''),
                      width: 90,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 30),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Car info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedCar!['brand']} ${_selectedCar!['model']}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 13, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCar!['rating']?.toString() ?? '0.0',
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on, size: 13, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _selectedCar!['location'] ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                '₱${_selectedCar!['price']}/day',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CarDetailScreen(
                                      carId: int.tryParse(_selectedCar!['id'].toString()) ?? 0,
                                      carName: '${_selectedCar!['brand']} ${_selectedCar!['model']}',
                                      carImage: getImageUrl(_selectedCar!['image'] ?? ''),
                                      price: _selectedCar!['price']?.toString() ?? '0',
                                      rating: double.tryParse(_selectedCar!['rating']?.toString() ?? '0.0') ?? 0.0,
                                      location: _selectedCar!['location'] ?? 'Unknown',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
