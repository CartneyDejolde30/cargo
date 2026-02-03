import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/config/maptiler_config.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/widgets/map_controls.dart';
import 'package:flutter_application_1/widgets/map_style_switcher.dart';
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

  @override
  void initState() {
    super.initState();
    _buildMarkers();
    _calculateCenter();
  }

  void _buildMarkers() {
    _markers = widget.cars.where((car) {
      return car['latitude'] != null && 
             car['longitude'] != null &&
             car['latitude'] != 0 &&
             car['longitude'] != 0;
    }).map((car) {
      final lat = double.tryParse(car['latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(car['longitude'].toString()) ?? 0.0;
      
      return Marker(
        point: LatLng(lat, lng),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showCarDetails(car),
          child: Stack(
            children: [
              // Custom marker
              Container(
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
              // Price badge
              if (car['price'] != null)
                Positioned(
                  bottom: -8,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '₱${car['price']}',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.cars.length} cars',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
              onCenterLocation: () {
                if (_markers.isNotEmpty) {
                  _mapController.move(_center, 12);
                }
              },
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
                              _selectedCar!['rating']?.toString() ?? '5.0',
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
                                      rating: double.tryParse(_selectedCar!['rating']?.toString() ?? '5.0') ?? 5.0,
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
