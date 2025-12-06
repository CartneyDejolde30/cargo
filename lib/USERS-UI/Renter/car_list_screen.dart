import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../Renter/search_filter_screen.dart';
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
  String _selectedCategory = 'All';
  int _selectedNavIndex = 0;

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
    return "http://192.168.1.11/carGOAdmin/uploads/${path.replaceFirst("uploads/", "")}";
  }

  Future<void> fetchCars() async {
    const url = "http://192.168.1.11/carGOAdmin/api/get_cars.php";

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() => _cars = List<Map<String, dynamic>>.from(data['cars']));
        }
      }
    } catch (e) {
      print("❌ ERROR LOADING CARS: $e");
    }

    setState(() => _loading = false);
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
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        _buildCategoryFilter(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Newly Listed",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),
                  _buildCarGrid(),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: false,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.title,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchFilterScreen(),
          ),
        );

        if (result != null && result is Map<String, dynamic>) {
          print("Search parameters: $result");
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Search your dream car...",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
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
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final car = _cars[index];
            return _buildCarCard(
              carId: int.tryParse(car['id'].toString()) ?? 0,
              name: "${car['brand']} ${car['model']}",
              year: car['car_year'] ?? "",
              rating: double.tryParse(car['rating'].toString()) ?? 5.0,
              location: car['location'].isEmpty ? "Unknown" : car['location'],
              price: car['price'],
              seats: int.tryParse(car['seat'].toString()) ?? 4,
              transmission: car['transmission'] ?? "Automatic",
              image: getImageUrl(car['image']),
              hasUnlimitedMileage: car['has_unlimited_mileage'] == 1,
            );
          },
          childCount: _cars.length,
        ),
      ),
    );
  }

  Widget _buildCarCard({
    required int carId,
    required String name,
    required String year,
    required double rating,
    required String location,
    required String price,
    required int seats,
    required String transmission,
    required String image,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    image,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                if (hasUnlimitedMileage)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Unlimited Mileage",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Car Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      "₱${price}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Car Name & Year
                    Text(
                      "$name $year",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Location & Rating
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
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

                    // Specs
                    Row(
                      children: [
                        Icon(Icons.event_seat, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "$seats-seater",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.speed, size: 12, color: Colors.grey.shade600),
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