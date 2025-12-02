import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/USERS-UI/Owner/widgets/verify_popup.dart';
import '../Renter/widgets/bottom_nav_bar.dart';
import 'car_list_screen.dart';
import '../Renter/chats/chat_list_screen.dart';
import 'car_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    fetchCars();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) VerifyPopup.showIfNotVerified(context);
    });
  }

  String formatImage(String rawPath) {
    if (rawPath.isEmpty) {
      return "https://via.placeholder.com/300";
    }

    String cleanPath = rawPath.replaceFirst("uploads/", "");
    return "http://192.168.1.11/carGOAdmin/uploads/$cleanPath";
  }

  Future<void> fetchCars() async {
    final String apiUrl = "http://192.168.1.11/carGOAdmin/api/get_cars.php";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['status'] == 'success') {
          setState(() {
            _cars = List<Map<String, dynamic>>.from(decoded['cars']);
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching cars: $e");
    }

    setState(() => _isLoading = false);
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
      backgroundColor: Colors.white,
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Search vehicle near you...",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton(
                      "Car",
                      _selectedVehicleType == 'car',
                      () => setState(() => _selectedVehicleType = 'car'),
                    ),
                    const SizedBox(width: 12),
                    _buildToggleButton(
                      "Motorcycle",
                      _selectedVehicleType == 'motorcycle',
                      () => setState(() => _selectedVehicleType = 'motorcycle'),
                    ),
                  ],
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
                    ? const Center(child: CircularProgressIndicator())
                    : _cars.isEmpty
                        ? const Center(child: Text("No cars available"))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: bestCars.length,
                            itemBuilder: (context, index) {
                              final car = bestCars[index];
                              return _buildCarCard(
                                carId: int.tryParse(car['id'].toString()) ?? 0,
                                image: formatImage(car['image'] ?? ""),
                                name: "${car['brand']} ${car['model']}",
                                rating: double.tryParse(car['rating'].toString()) ?? 5.0,
                                location: car['location'].toString().isEmpty ? "Unknown" : car['location'],
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
                    ? const Center(child: CircularProgressIndicator())
                    : newlyListed.isEmpty
                        ? const Center(child: Text("No new listings"))
                        : SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: newlyListed.length,
                              itemBuilder: (context, index) {
                                final car = newlyListed[index];
                                return _buildNewlyListedCard(
                                  carId: int.tryParse(car['id'].toString()) ?? 0,
                                  image: formatImage(car['image'] ?? ""),
                                  name: "${car['brand']} ${car['model']}",
                                  year: car['car_year'] ?? "",
                                  location: car['location'].toString().isEmpty ? "Unknown" : car['location'],
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(color: selected ? Colors.white : Colors.black),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                image,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_seat, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "$seats Seats",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₱$price/day",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
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
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                if (hasUnlimitedMileage)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Unlimited Mileage",
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "₱$price",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$name $year",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_seat, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "$seats-seater",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.speed, size: 14, color: Colors.grey.shade600),
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