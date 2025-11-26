import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/USERS-UI/Owner/widgets/verify_popup.dart';
import '../Renter/widgets/bottom_nav_bar.dart';
import 'car_list_screen.dart';
import '../Renter/chats/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
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

  /// --- Fix image path builder ---
  String formatImage(String rawPath) {
    if (rawPath.isEmpty) {
      return "https://via.placeholder.com/300";
    }

    String cleanPath = rawPath.replaceFirst("uploads/", "");

    return "http://10.72.15.180/carGOAdmin/uploads/$cleanPath";
  }

  Future<void> fetchCars() async {
    final String apiUrl = "http://10.72.15.180/carGOAdmin/api/get_cars.php";

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

    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CarListScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text("CARGO", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                _buildSearch(),
                const SizedBox(height: 20),

                _buildToggleOptions(),
                const SizedBox(height: 20),

                _buildSectionHeader("Best Cars", "View All"),
                const SizedBox(height: 8),

                Text("Available", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
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
                            itemCount: _cars.length,
                            itemBuilder: (context, index) {
                              final car = _cars[index];
                              return _buildCarCard(
                                image: formatImage(car['image'] ?? ""),
                                name: "${car['brand']} ${car['model']}",
                                rating: double.tryParse(car['rating'].toString()) ?? 5.0,
                                location: car['location'].toString().isEmpty ? "Unknown" : car['location'],
                                seats: (int.tryParse(car['seats'].toString()) ?? 0) > 0 ? int.parse(car['seats'].toString()) : 4,
                                price: "₱${car['price']}/day",
                              );
                            },
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

  ///------------- UI Widgets (no layout change) ----------------

  Widget _buildSearch() => Container(
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: "Search your dream vehicle...", border: InputBorder.none),
              ),
            ),
          ],
        ),
      );

  Widget _buildToggleOptions() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton("Car", _selectedVehicleType == "car", () => setState(() => _selectedVehicleType = "car")),
          const SizedBox(width: 12),
          _buildToggleButton("Motorcycle", _selectedVehicleType == "motorcycle", () => setState(() => _selectedVehicleType = "motorcycle")),
        ],
      );

  Widget _buildToggleButton(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(color: selected ? Colors.black : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: GoogleFonts.poppins(color: selected ? Colors.white : Colors.black)),
        ),
      );

  Widget _buildSectionHeader(String title, String action) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarListScreen())),
            child: Text(action, style: GoogleFonts.poppins(color: Colors.grey)),
          ),
        ],
      );

  Widget _buildCarCard({
    required String image,
    required String name,
    required double rating,
    required String location,
    required int seats,
    required String price,
  }) {
    return Container(
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
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Row(children: [Icon(Icons.star, color: Colors.amber, size: 14), Text(rating.toString())]),
                Row(children: [Icon(Icons.event_seat, size: 14), Text("$seats Seats")]),
                Text(price, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
