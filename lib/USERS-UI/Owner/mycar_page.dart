import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'car_listing/car_details.dart';
import 'models/car_listing.dart';

class MyCarPage extends StatefulWidget {
  final int ownerId;
  const MyCarPage({super.key, required this.ownerId});

  @override
  State<MyCarPage> createState() => _MyCarPageState();
}

class _MyCarPageState extends State<MyCarPage> {
  final String apiUrl = "http://192.168.1.11/carGOAdmin/cars_api.php";

  List<Map<String, dynamic>> cars = [];
  List<Map<String, dynamic>> filteredCars = [];

  bool isLoading = true;
  String searchQuery = "";
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    fetchCars();
  }

  /* ---------------- FETCH DATA ---------------- */
  Future<void> fetchCars() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse("$apiUrl?owner_id=${widget.ownerId}"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          cars = List<Map<String, dynamic>>.from(data);
          applyFilters();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching cars: $e");
    }

    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => isLoading = false);
  }

  /* ---------------- FILTER LOGIC ---------------- */
  void applyFilters() {
    String query = searchQuery.toLowerCase();

    filteredCars = cars.where((car) {
      final brand = car['brand'].toString().toLowerCase();
      final model = car['model'].toString().toLowerCase();
      final status = car["status"]?.toString().toLowerCase() ?? "";

      final matchesSearch = brand.contains(query) || model.contains(query);
      final matchesFilter =
          selectedFilter == "All" ||
              selectedFilter.toLowerCase() == car["status"].toString().toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();

    setState(() {});
  }

  /* ---------------- DELETE CAR ---------------- */
  Future<void> deleteCar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Delete Car?",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Are you sure you want to delete this car?",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        "action": "delete",
        "id": id.toString(),
      });

      final result = jsonDecode(response.body);

      if (result["success"] == true) {
        cars.removeWhere((car) => car["id"].toString() == id.toString());
        applyFilters();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Car deleted successfully',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Delete error: $e");
    }
  }

  /* ---------------- COLOR BASED ON STATUS ---------------- */
  Color getStatusColor(String status) {
    final normalized = status.trim().toLowerCase();

    if (normalized == "approved") return Colors.green;
    if (normalized == "pending") return Colors.orange;
    if (normalized == "rejected") return Colors.redAccent;
    if (normalized == "rented") return Colors.blueAccent;

    return Colors.grey;
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "My Cars",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset("assets/cargo.png", width: 32),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => CarDetailsScreen(ownerId: widget.ownerId),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
          if (result == true) fetchCars();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Add Car",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                searchQuery = value;
                applyFilters();
              },
              decoration: InputDecoration(
                hintText: "Search car...",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          setState(() {
                            searchQuery = "";
                            applyFilters();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Car List
          Expanded(
            child: isLoading
                ? _buildShimmer()
                : filteredCars.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCars.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: .80,
                        ),
                        itemBuilder: (_, index) {
                          final car = filteredCars[index];
                          final imageUrl = "http://192.168.1.11/carGOAdmin/${car['image']}";
                          final status = car["status"] ?? "Unknown";

                          return FadeInUp(
                            duration: Duration(milliseconds: 200 + (index * 50)),
                            child: _carCard(car, imageUrl, status),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }

  /* ---------------- EMPTY STATE ---------------- */
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isEmpty ? "No cars yet" : "No matching results",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? "Add your first car to get started"
                : "Try adjusting your search",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /* ---------------- CAR CARD ---------------- */
  Widget _carCard(Map<String, dynamic> car, String imageUrl, String status) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image with Preview
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 300,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.directions_car,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.directions_car,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(status),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: getStatusColor(status).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      car["status"].toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Car Details
          Expanded(
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarDetailsScreen(
                      ownerId: widget.ownerId,
                      existingListing: CarListing.fromJson(car),
                    ),
                  ),
                );

                if (result == true) fetchCars();
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${car['brand']} ${car['model']}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "₱ ${car['price_per_day']}/day",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Menu Button
                    Align(
                      alignment: Alignment.bottomRight,
                      child: PopupMenuButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        offset: const Offset(0, 10),
                        onSelected: (value) {
                          if (value == "delete") {
                            deleteCar(int.parse(car["id"].toString()));
                          }
                          if (value == "edit") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CarDetailsScreen(
                                  ownerId: widget.ownerId,
                                  existingListing: CarListing.fromJson(car),
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: "edit",
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade700),
                                const SizedBox(width: 12),
                                Text(
                                  "Edit",
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: "delete",
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                const SizedBox(width: 12),
                                Text(
                                  "Delete",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
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
            ),
          )
        ],
      ),
    );
  }

  /* ---------------- SHIMMER LOADER ---------------- */
  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: .80,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}