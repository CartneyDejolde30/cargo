import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';

import 'package:flutter_application_1/USERS-UI/Owner/widgets/verify_popup.dart';
import '../Renter/widgets/bottom_nav_bar.dart';
import 'car_list_screen.dart';
import '../Renter/chats/chat_list_screen.dart';
import 'car_detail_screen.dart';
import 'widgets/favorite_button.dart';
import 'widgets/notification_icon.dart';

import 'motorcycle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  String _selectedVehicleType = 'car';

  bool _isLoading = true;
  List<Map<String, dynamic>> _cars = [];

Future<void> saveFcmToken() async {
  String? token = await FirebaseMessaging.instance.getToken();

  if (token == null) return;

  // Get user id (assuming you stored it in SharedPreferences)
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString("user_id");

  if (userId == null) return;

  final url = Uri.parse(GlobalApiConfig.saveFcmTokenEndpoint);

  await http.post(url, body: {
    "user_id": userId,
    "fcm_token": token,
  });

  print("🔥 FCM Token saved: $token");
}


  @override
void initState() {
  super.initState();
  fetchCars();
  saveFcmToken();  // <-- ADD THIS

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) VerifyPopup.showIfNotVerified(context);
  });
}

  /// Synchronous formatter (keeps behavior for quick usage).
  /// Accepts nullable input and always returns a non-null URL string.
  String formatImage(String? rawPath) {
    final path = rawPath?.toString().trim() ?? '';
    if (path.isEmpty) return "https://via.placeholder.com/300";

    if (path.startsWith("http://") || path.startsWith("https://")) return path;

    final cleanPath = path.replaceFirst("uploads/", "");
    return GlobalApiConfig.getImageUrl(cleanPath);
  }


  Future<void> fetchCars() async {
    final String apiUrl = GlobalApiConfig.getCarsEndpoint;

    try {
      // ✅ CRASH FIX: Add timeout to prevent hanging
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        // ✅ CRASH FIX: Wrap jsonDecode in try-catch
        try {
          final decoded = jsonDecode(response.body);

          if (decoded['status'] == 'success') {
            // ✅ CRASH FIX: Check mounted before setState
            if (!mounted) return;
            setState(() {
              _cars = List<Map<String, dynamic>>.from(decoded['cars']);
            });
          }
        } catch (jsonError) {
          print("❌ JSON decode error: $jsonError");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error loading car data')),
            );
          }
        }
      } else {
        print("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching cars: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('timeout') 
              ? 'Connection timeout. Please check your internet.' 
              : 'Failed to load cars. Please try again.'),
          ),
        );
      }
    }

    // ✅ CRASH FIX: Check mounted before setState
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleNavigation(int index) {
    setState(() => _selectedNavIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CarListScreen()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get best cars (first 4) and newly listed (last 3)
    final bestCars = _cars.take(4).toList();
    final newlyListed = _cars.length > 3 ? _cars.skip(_cars.length - 3).toList() : _cars;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CARGO",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const NotificationIcon(),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CarListScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,

                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                                            Icon(
                      Icons.search,
                      color: Theme.of(context).iconTheme.color,
                      size: 22,
                    ),

                                            const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Search vehicle near you...",
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).hintColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Vehicle Type Toggle
                 Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,

    borderRadius: BorderRadius.circular(25),
  ),
  child: Row(
    children: [
      Expanded(
        child: _buildToggleButton(
          "Car",
          _selectedVehicleType == 'car',
          () => setState(() => _selectedVehicleType = 'car'),
        ),
      ),
      Expanded(
        child: _buildToggleButton(
          "Motorcycle",
          _selectedVehicleType == 'motorcycle',
          () {
            // Navigate to motorcycle screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MotorcycleScreen(),
              ),
            );
          },
        ),
      ),
    ],
  ),
),
                const SizedBox(height: 20),

                // Best Cars Section
                _buildSectionHeader("Best Cars", "View All"),
                const SizedBox(height: 8),
                Text(
                  "Available",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _cars.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No cars available",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: bestCars.length,
                            itemBuilder: (context, index) {
                              final car = bestCars[index];

                              // normalize location safely
                              final rawLocation = (car['location'] ?? '').toString().trim();
                              final locationText = rawLocation.isEmpty ? "Unknown" : rawLocation;

                              return _buildCarCard(
                                carId: int.tryParse(car['id'].toString()) ?? 0,
                                image: formatImage(car['image'] ?? ''),
                                name: "${car['brand']} ${car['model']}",
                                rating: double.tryParse(car['rating'].toString()) ?? 5.0,
                                location: locationText,
                                seats: int.tryParse(car['seat'].toString()) ?? 4,
                                price: car['price'].toString(),
                              );
                            },
                          ),

                const SizedBox(height: 32),

                // Newly Listed Section
                _buildSectionHeader("Newly Listed", "See more", color: Colors.green),
                const SizedBox(height: 12),

                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : newlyListed.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.new_releases_outlined,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No new listings",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 0),
                              itemCount: newlyListed.length,
                              itemBuilder: (context, index) {
                                final car = newlyListed[index];

                                final rawLocation = (car['location'] ?? '').toString().trim();
                                final locationText = rawLocation.isEmpty ? "Unknown" : rawLocation;

                                return _buildNewlyListedCard(
                                  carId: int.tryParse(car['id'].toString()) ?? 0,
                                  image: formatImage(car['image'] ?? ''),
                                  name: "${car['brand']} ${car['model']}",
                                  year: car['car_year'] ?? "",
                                  location: locationText,
                                  seats: int.tryParse(car['seat'].toString()) ?? 4,
                                  transmission: car['transmission'] ?? "Automatic",
                                  price: car['price'].toString(),
                                  hasUnlimitedMileage: car['has_unlimited_mileage'] == 1,
                                );
                              },
                            ),
                          ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildToggleButton(String label, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? Theme.of(context).colorScheme.surface : Theme.of(context).dividerColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, String action, {Color color = Colors.grey}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CarListScreen()),
          ),
          child: Text(
            action,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard({
    required int carId,
    required String image,
    required String name,
    required double rating,
    required String location,
    required int seats,
    required String price,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarDetailScreen(
              carId: carId,
              carName: name,
              carImage: image,
              price: price,
              rating: rating,
              location: location,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with aspect ratio
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    image,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.directions_car, size: 50, color: Colors.grey),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: FavoriteButton(
                      vehicleType: 'car',
                      vehicleId: carId,
                      size: 20,
                    ),
                  ),
                  // Rating badge overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
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

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Car name
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Seats
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "$seats Seats",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Price
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "₱$price/day",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewlyListedCard({
    required int carId,
    required String image,
    required String name,
    required String year,
    required String location,
    required int seats,
    required String transmission,
    required String price,
    bool hasUnlimitedMileage = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarDetailScreen(
              carId: carId,
              carName: name,
              carImage: image,
              price: price,
              rating: 5.0,
              location: location,
            ),
          ),
        );
      },
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.network(
                    image,
                    height: 160,
                    width: 140,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        width: 140,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.directions_car, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                // "NEW" badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "NEW",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Unlimited mileage badge
                if (hasUnlimitedMileage)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.all_inclusive, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "Unlimited",
                            style: GoogleFonts.poppins(
                              fontSize: 9,
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

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Car name and year
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          year,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
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
                    
                    // Seats and transmission
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$seats",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.settings,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            transmission,
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
                    
                    const SizedBox(height: 12),
                    
                    // Price
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "₱$price/day",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
