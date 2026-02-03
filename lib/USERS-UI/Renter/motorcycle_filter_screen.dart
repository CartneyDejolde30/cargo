import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_config.dart';

class MotorcycleFilterScreen extends StatefulWidget {
  final Map<String, dynamic>? currentFilters;
  
  const MotorcycleFilterScreen({
    super.key,
    this.currentFilters,
  });

  @override
  State<MotorcycleFilterScreen> createState() => _MotorcycleFilterScreenState();
}

class _MotorcycleFilterScreenState extends State<MotorcycleFilterScreen> {
  final TextEditingController _locationController = TextEditingController();
  String _selectedDeliveryMethod = '';
  RangeValues _priceRange = const RangeValues(0, 5000);
  bool _isLoadingLocation = false;
  
  // Additional filter options
  String _selectedTransmission = '';
  String _selectedBodyStyle = '';
  String _selectedBrand = '';
  String _selectedYear = '';
  String _selectedEngineSize = '';
  
  // Filter options from API
  Map<String, dynamic> _filterOptions = {};
  bool _isLoadingOptions = true;
  
  // Price range based on actual data: ₱500 - ₱5000 per day
  static const double _minPriceLimit = 0;
  static const double _maxPriceLimit = 5000;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    // Load existing filters if provided
    if (widget.currentFilters != null) {
      _locationController.text = widget.currentFilters!['location'] ?? '';
      _selectedDeliveryMethod = widget.currentFilters!['deliveryMethod'] ?? '';
      _selectedTransmission = widget.currentFilters!['transmission'] ?? '';
      _selectedBodyStyle = widget.currentFilters!['bodyStyle'] ?? '';
      _selectedBrand = widget.currentFilters!['brand'] ?? '';
      _selectedYear = widget.currentFilters!['year'] ?? '';
      _selectedEngineSize = widget.currentFilters!['engineSize'] ?? '';
      if (widget.currentFilters!['minPrice'] != null) {
        _priceRange = RangeValues(
          widget.currentFilters!['minPrice'],
          widget.currentFilters!['maxPrice'],
        );
      }
    }
  }
  
  Future<void> _loadFilterOptions() async {
    try {
<<<<<<< HEAD
      const url = "http://10.77.127.2/carGOAdmin/api/get_motorcycle_filter_options.php";
=======
      final url = GlobalApiConfig.getMotorcycleFilterOptionsEndpoint;
>>>>>>> 9adbf571a7283327b292d84ace8551a819d8984e
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _filterOptions = data['options'];
            _isLoadingOptions = false;
          });
        }
      }
    } catch (e) {
      print("Error loading filter options: $e");
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "${place.locality ?? ""}, ${place.administrativeArea ?? ""}".trim();
        
        setState(() {
          _locationController.text = address.isEmpty ? "Current Location" : address;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location set to: ${_locationController.text}'),
              backgroundColor: Theme.of(context).iconTheme.color,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get location: ${e.toString()}'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showDeliveryMethodModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Delivery Method',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeliveryOption('Guest Pick-up and Guest Return'),
            _buildDeliveryOption('Guest Pick-up and Host Collection'),
            _buildDeliveryOption('Host Delivery and Guest Return'),
            _buildDeliveryOption('Host Delivery and Host Collection'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(String option) {
    bool isSelected = _selectedDeliveryMethod == option;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDeliveryMethod = option;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String text, bool isEmpty, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).iconTheme.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isEmpty ? Colors.grey.shade600 : Colors.black,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Theme.of(context).iconTheme.color),
        ],
      ),
    );
  }

  void _showSingleSelectModal(String title, List<dynamic> options, String selectedValue, Function(String) onSelect) {
    if (_isLoadingOptions || options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLoadingOptions ? 'Loading options...' : 'No options available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSelectOption('Any', '', selectedValue, onSelect);
                  }
                  String option = options[index - 1].toString();
                  return _buildSelectOption(option, option, selectedValue, onSelect);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectOption(String displayText, String value, String selectedValue, Function(String) onSelect) {
    bool isSelected = selectedValue == value;
    return InkWell(
      onTap: () {
        onSelect(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _locationController.clear();
      _selectedDeliveryMethod = '';
      _selectedTransmission = '';
      _selectedBodyStyle = '';
      _selectedBrand = '';
      _selectedYear = '';
      _selectedEngineSize = '';
      _priceRange = const RangeValues(0, 5000);
    });
  }

  void _search() {
    Map<String, dynamic> searchParams = {
      'location': _locationController.text,
      'deliveryMethod': _selectedDeliveryMethod,
      'transmission': _selectedTransmission,
      'bodyStyle': _selectedBodyStyle,
      'brand': _selectedBrand,
      'year': _selectedYear,
      'engineSize': _selectedEngineSize,
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
    };
    
    Navigator.pop(context, searchParams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).iconTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        title: Text(
          'Search a motorcycle',
          style: GoogleFonts.poppins(
            color: Theme.of(context).iconTheme.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pickup Location',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).iconTheme.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _isLoadingLocation
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : TextButton.icon(
                              onPressed: _useCurrentLocation,
                              icon: Icon(
                                Icons.my_location,
                                color: Theme.of(context).iconTheme.color,
                                size: 18,
                              ),
                              label: Text(
                                'Motorcycles Near Me',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Theme.of(context).iconTheme.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).iconTheme.color,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter location',
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Range Section
                  Text(
                    'Price Range',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₱${_priceRange.start.round()}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                            Text(
                              '₱${_priceRange.end.round()}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: _minPriceLimit,
                          max: _maxPriceLimit,
                          divisions: 100,
                          activeColor: Theme.of(context).iconTheme.color,
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (RangeValues values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delivery Method Section
                  Text(
                    'Delivery Method',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showDeliveryMethodModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDeliveryMethod.isEmpty
                                  ? 'Choose delivery method'
                                  : _selectedDeliveryMethod,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _selectedDeliveryMethod.isEmpty
                                    ? Colors.grey.shade600
                                    : Colors.black,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Section
                  Text(
                    'Brand',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showSingleSelectModal(
                      'Select Brand',
                      _filterOptions['brands'] ?? [],
                      _selectedBrand,
                      (value) => setState(() => _selectedBrand = value),
                    ),
                    child: _buildDropdownField(
                      _selectedBrand.isEmpty ? 'Choose brand' : _selectedBrand,
                      _selectedBrand.isEmpty,
                      Icons.two_wheeler,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Body Style Section
                  Text(
                    'Type',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showSingleSelectModal(
                      'Select Type',
                      _filterOptions['bodyStyles'] ?? [],
                      _selectedBodyStyle,
                      (value) => setState(() => _selectedBodyStyle = value),
                    ),
                    child: _buildDropdownField(
                      _selectedBodyStyle.isEmpty ? 'Choose type' : _selectedBodyStyle,
                      _selectedBodyStyle.isEmpty,
                      Icons.category,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transmission Section
                  Text(
                    'Transmission',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showSingleSelectModal(
                      'Select Transmission',
                      _filterOptions['transmissions'] ?? [],
                      _selectedTransmission,
                      (value) => setState(() => _selectedTransmission = value),
                    ),
                    child: _buildDropdownField(
                      _selectedTransmission.isEmpty ? 'Choose transmission' : _selectedTransmission,
                      _selectedTransmission.isEmpty,
                      Icons.settings,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Year Section
                  Text(
                    'Year',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showSingleSelectModal(
                      'Select Year',
                      _filterOptions['years'] ?? [],
                      _selectedYear,
                      (value) => setState(() => _selectedYear = value),
                    ),
                    child: _buildDropdownField(
                      _selectedYear.isEmpty ? 'Choose year' : _selectedYear,
                      _selectedYear.isEmpty,
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Engine Size Section
                  Text(
                    'Engine Size',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).iconTheme.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showSingleSelectModal(
                      'Select Engine Size',
                      _filterOptions['engineSizes'] ?? [],
                      _selectedEngineSize,
                      (value) => setState(() => _selectedEngineSize = value),
                    ),
                    child: _buildDropdownField(
                      _selectedEngineSize.isEmpty ? 'Choose engine size' : _selectedEngineSize,
                      _selectedEngineSize.isEmpty,
                      Icons.speed,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAll,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.black, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).iconTheme.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
