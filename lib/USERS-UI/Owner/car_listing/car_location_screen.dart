import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/config/maptiler_config.dart';
import 'package:flutter_application_1/services/maptiler_geocoding_service.dart';

import 'package:flutter_application_1/USERS-UI/Owner/models/car_listing.dart';
import 'upload_documents_screen.dart';

class CarLocationScreen extends StatefulWidget {
  final CarListing listing;
  final String vehicleType;

  const CarLocationScreen({
    super.key, 
    required this.listing, 
    this.vehicleType = 'car',
  });

  @override
  State<CarLocationScreen> createState() => _CarLocationScreenState();
}

class _CarLocationScreenState extends State<CarLocationScreen> {
  final _locationController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final MapController _mapController = MapController();

  bool _showMap = false;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  
  // Location suggestions
  List<Place> _suggestions = [];
  bool _showSuggestions = false;

  // Default location (Agusan del Sur - Prosperidad, the capital)
  LatLng _currentPosition = LatLng(8.6011, 125.9094);
  List<Marker> _markers = [];
  
  // Location accuracy
  String _locationAccuracy = '';
  bool _isLocationVerified = false;


  @override
  void initState() {
    super.initState();

    if (widget.listing.location != null) {
      _locationController.text = widget.listing.location!;
      _isLocationVerified = true;
    }

    if (widget.listing.latitude != null && widget.listing.longitude != null) {
      _currentPosition = LatLng(widget.listing.latitude!, widget.listing.longitude!);
      _isLocationVerified = true;
    }

    _addMarker(_currentPosition);
    _requestLocationPermission();

    // Listen to text changes for autocomplete
    _locationController.addListener(_onSearchChanged);
    
    // Listen to focus changes
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.listing.latitude != null && widget.listing.longitude != null) {
        _mapController.move(_currentPosition, 15);
      }
    });
  }

  @override
  void dispose() {
    _locationController.removeListener(_onSearchChanged);
    _locationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _locationController.text.trim();
    
    if (query.length >= 3) {
      _performSearch(query);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);

    try {
      // Add "Agusan del Sur" to query for location-specific results
      final searchQuery = "$query, Agusan del Sur, Philippines";
      final places = await MapTilerGeocodingService.searchPlaces(searchQuery);
      
      // Filter results to only include Agusan del Sur locations
      final filteredPlaces = places.where((place) {
        final address = place.address.toLowerCase();
        return address.contains('agusan del sur') || 
               _isWithinAgusanDelSur(place.coordinates.latitude, place.coordinates.longitude);
      }).toList();
      
      setState(() {
        _suggestions = filteredPlaces;
        _showSuggestions = filteredPlaces.isNotEmpty;
        _isSearching = false;
      });
      
      if (filteredPlaces.isEmpty && places.isNotEmpty) {
        // Show message that no results in Agusan del Sur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No results found in Agusan del Sur. Please try another search."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _showSuggestions = false;
      });
      print('Search error: $e');
    }
  }
  
  bool _isWithinAgusanDelSur(double lat, double lng) {
    // Agusan del Sur boundaries (approximate)
    // North: ~8.9°, South: ~8.0°, East: ~126.4°, West: ~125.4°
    const minLat = 8.0;
    const maxLat = 8.9;
    const minLng = 125.4;
    const maxLng = 126.4;
    
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  void _selectPlace(Place place) {
    // Validate location is within Agusan del Sur before selecting
    if (!_isWithinAgusanDelSur(place.coordinates.latitude, place.coordinates.longitude)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ Selected location is outside Agusan del Sur"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() {
      _locationController.text = place.address;
      widget.listing.location = place.address;
      widget.listing.latitude = place.coordinates.latitude;
      widget.listing.longitude = place.coordinates.longitude;
      _currentPosition = place.coordinates;
      _addMarker(place.coordinates);
      _showSuggestions = false;
      _showMap = true;
      _isLocationVerified = true;
      
      // Set accuracy based on place type
      _locationAccuracy = _getAccuracyLabel(place.placeType);
    });

    _mapController.move(place.coordinates, 15);
    _searchFocusNode.unfocus();
  }

  String _getAccuracyLabel(String placeType) {
    switch (placeType) {
      case 'address':
        return 'Exact Address';
      case 'poi':
        return 'Point of Interest';
      case 'place':
        return 'City/Town';
      case 'region':
        return 'Region';
      default:
        return 'Approximate';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied');
        }
      }

      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      LatLng newPos = LatLng(pos.latitude, pos.longitude);

      await _updateAddressFromCoordinates(newPos);

      setState(() {
        widget.listing.latitude = pos.latitude;
        widget.listing.longitude = pos.longitude;
        _currentPosition = newPos;
        _addMarker(newPos);
        _showMap = true;
        _isLocationVerified = true;
        _locationAccuracy = 'GPS - High Accuracy';
      });

      _mapController.move(newPos, 15);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Current location detected"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unable to get location: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoadingLocation = false);
  }

  Future<void> _updateAddressFromCoordinates(LatLng pos) async {
    try {
      final address = await MapTilerGeocodingService.getAddressFromCoordinates(pos);

      if (address != null) {
        setState(() {
          _locationController.text = address;
          widget.listing.location = address;
        });
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
  }

  bool _validateLocation() {
    // Validate if location is in Agusan del Sur
    if (widget.listing.latitude == null || widget.listing.longitude == null) {
      return false;
    }

    final lat = widget.listing.latitude!;
    final lng = widget.listing.longitude!;

    // Check if within Agusan del Sur boundaries
    if (!_isWithinAgusanDelSur(lat, lng)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠ Location must be within Agusan del Sur only"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    return true;
  }

  void _addMarker(LatLng pos) {
    _markers = [
      Marker(
        point: pos,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
      ),
    ];
  }

  IconData _getPlaceIcon(String placeType) {
    switch (placeType) {
      case 'address':
        return Icons.home;
      case 'poi':
        return Icons.place;
      case 'place':
        return Icons.location_city;
      case 'region':
        return Icons.map;
      case 'country':
        return Icons.public;
      default:
        return Icons.location_on;
    }
  }

  bool get _canContinue {
    return widget.listing.location != null &&
        widget.listing.location!.trim().isNotEmpty &&
        widget.listing.latitude != null &&
        widget.listing.longitude != null &&
        _isLocationVerified;
  }

  void _continue() {
    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid location before continuing."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate location is within service area
    if (!_validateLocation()) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadDocumentsScreen(
          listing: widget.listing,
          vehicleType: widget.vehicleType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Location", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your Location",
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),

                        Text("Set pickup and return location in Agusan del Sur.",
                            style: GoogleFonts.poppins(color: Colors.black87)),

                        const SizedBox(height: 20),

                        // Search field with autocomplete
                        TextField(
                          controller: _locationController,
                          focusNode: _searchFocusNode,
                          onChanged: (v) {
                            widget.listing.location = v;
                            _isLocationVerified = false;
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on, color: Colors.black),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _locationController.clear();
                                      setState(() {
                                        _suggestions = [];
                                        _showSuggestions = false;
                                        _isLocationVerified = false;
                                      });
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            hintText: "Search in Agusan del Sur...",
                            helperText: "Start typing to see suggestions (Agusan del Sur only)",
                            helperStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                    // Location accuracy indicator
                    if (_isLocationVerified && _locationAccuracy.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location verified: $_locationAccuracy',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () => setState(() => _showMap = !_showMap),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Pin on Map", style: GoogleFonts.poppins(fontSize: 14)),
                          Icon(_showMap ? Icons.expand_less : Icons.expand_more, color: Colors.black)
                        ],
                      ),
                    ),

                    if (_showMap) ...[
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 300,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition,
                            initialZoom: 15,
                            onTap: (tapPosition, point) async {
                              setState(() {
                                _currentPosition = point;
                                widget.listing.latitude = point.latitude;
                                widget.listing.longitude = point.longitude;
                                _addMarker(point);
                                _isLocationVerified = true;
                                _locationAccuracy = 'Manual Selection';
                              });

                              await _updateAddressFromCoordinates(point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  MapTilerConfig.getTileUrl(MapTilerConfig.defaultStyle),
                            ),
                            MarkerLayer(markers: _markers),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Icon(Icons.my_location),
                        label: Text(_isLoadingLocation ? "Locating..." : "Use Current Location"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      ),
                      ],
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canContinue ? Colors.black : Colors.grey,
                      disabledBackgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Continue",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Suggestions dropdown - positioned outside ScrollView
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 190, // Position below the search field
              left: 24,
              right: 24,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_city, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Locations in Agusan del Sur',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // List
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, index) {
                            final place = _suggestions[index];
                            return InkWell(
                              onTap: () => _selectPlace(place),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getPlaceIcon(place.placeType),
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place.name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            place.address,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ));
  }
}
