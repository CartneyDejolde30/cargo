import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../Renter/widgets/bottom_nav_bar.dart';
import 'car_detail_screen.dart';
import '../Renter/chats/chat_list_screen.dart';

class CarListScreen extends StatefulWidget {
  final String title;

  const CarListScreen({
    super.key,
    this.title = 'Search',
  });

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  int _selectedNavIndex = 1;

  List<Map<String, dynamic>> _cars = [];
  bool _loading = true;

  final List<String> _categories = ['All', 'SUV', 'Sedan', 'Sport', 'Coupe', 'Luxury'];

  @override
  void initState() {
    super.initState();
    fetchCars();
  }

  String getImageUrl(String path) {
    if (path.isEmpty) {
      return "https://via.placeholder.com/300";
    }

    // Remove duplicate folder reference if exists
    path = path.replaceFirst("uploads/", "");

    return "http://10.72.15.180/carGOAdmin/uploads/$path";
  }

  Future<void> fetchCars() async {
    const url = "http://10.72.15.180/carGOAdmin/api/get_cars.php";

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['status'] == 'success') {
          setState(() {
            _cars = List<Map<String, dynamic>>.from(data['cars']);
          });
        }
      }
    } catch (e) {
      print("❌ ERROR LOADING CARS: $e");
    }

    setState(() {
      _loading = false;
    });
  }

  void _handleNavigation(int index) {
    setState(() => _selectedNavIndex = index);

    if (index == 0) Navigator.pop(context);
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _loading ? _buildLoading() : _buildContent(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.title,
        style: GoogleFonts.poppins(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
      ],
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildCategoryFilter(),
            const SizedBox(height: 24),
            Text("Available Cars", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _cars.isEmpty
                ? const Center(child: Text("No cars available"))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _cars.length,
                    itemBuilder: (context, index) {
                      final car = _cars[index];

                      return _buildCarCard(
                        carId: int.tryParse(car['id'].toString()) ?? 0,
                        name: "${car['brand']} ${car['model']}",
                        rating: double.tryParse(car['rating'].toString()) ?? 5.0,
                        location: car['location'] == "" ? "Unknown" : car['location'],
                        price: "₱${car['price']}/day",
                        image: getImageUrl(car['image']),
                      );
                    },
                  ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search your dream car...",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.tune, size: 24),
      ),
    ]);
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(category,
                  style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.black, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarCard({
    required int carId,
    required String name,
    required double rating,
    required String location,
    required String price,
    required String image,
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
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                image,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.orange, size: 12),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: GoogleFonts.poppins(fontSize: 11)),
                  ]),
                  const SizedBox(height: 4),
                  Text(location, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(price, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
