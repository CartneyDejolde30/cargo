import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/config/maptiler_config.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/widgets/map_controls.dart';
import 'package:flutter_application_1/widgets/map_style_switcher.dart';
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

  @override
  void initState() {
    super.initState();
    _buildMarkers();
    _calculateCenter();
  }

  void _buildMarkers() {
    _markers = widget.motorcycles.where((motorcycle) {
      return motorcycle['latitude'] != null && 
             motorcycle['longitude'] != null &&
             motorcycle['latitude'] != 0 &&
             motorcycle['longitude'] != 0;
    }).map((motorcycle) {
      final lat = double.tryParse(motorcycle['latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(motorcycle['longitude'].toString()) ?? 0.0;
      
      return Marker(
        point: LatLng(lat, lng),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showMotorcycleDetails(motorcycle),
          child: Stack(
            children: [
              Container(
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
              if (motorcycle['price'] != null)
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
                      '₱${motorcycle['price']}',
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
                            '${motorcycle['rating'] ?? 5.0}',
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
                      rating: double.tryParse(motorcycle['rating'].toString()) ?? 5.0,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
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
                urlTemplate: _currentMapStyle,
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
              onCenterLocation: () {
                _mapController.move(_center, 13);
              },
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
