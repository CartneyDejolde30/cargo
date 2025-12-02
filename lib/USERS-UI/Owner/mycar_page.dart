import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'car_listing/car_details.dart';
import 'models/car_listing.dart';

class MyCarPage extends StatefulWidget {
  final int ownerId;
  const MyCarPage({super.key, required this.ownerId});

  @override
  State<MyCarPage> createState() => _MyCarPageState();
}

class _MyCarPageState extends State<MyCarPage> {
  final String apiUrl = "http://10.72.15.180/carGOAdmin/cars_api.php";

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
        title: const Text("Delete Car?"),
        content: const Text("Are you sure you want to delete this car?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
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

  return Colors.grey; // fallback
}


  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("My Cars", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset("assets/cargo.png", width: 40),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => CarDetailsScreen(ownerId: widget.ownerId),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
            ),
          );
          if (result == true) fetchCars();
        },
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                searchQuery = value;
                applyFilters();
              },
              decoration: InputDecoration(
                hintText: "Search car...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Car List
          Expanded(
            child: isLoading
                ? _buildShimmer()
                : filteredCars.isEmpty
                    ? const Center(child: Text("No matching results"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredCars.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .80,
                        ),
                        itemBuilder: (_, index) {
                          final car = filteredCars[index];
                          final imageUrl = "http://10.72.15.180/carGOAdmin/${car['image']}";
                          final status = car["status"] ?? "Unknown";

                          return FadeInUp(
                            duration: Duration(milliseconds: 200 + (index * 100)),
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CarDetailsScreen(ownerId: widget.ownerId, existingListing: CarListing.fromJson(car)),
                                  ),
                                );
                                if (result == true) fetchCars();
                              },
                              child: _carCard(car, imageUrl, status),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }

  /* ---------------- CAR CARD ---------------- */
  Widget _carCard(Map<String, dynamic> car, String imageUrl, String status) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: [
        BoxShadow( color: Colors.black.withAlpha((0.05 * 255).round()), blurRadius: 6, offset: const Offset(0, 3)),
      ],
    ),
    child: Column(
      children: [
        
        /// ✅ Image only opens preview, NOT edit
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),
            );
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      car["status"].toString().toUpperCase(),  // USE ORIGINAL TEXT
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

            ],
          ),
        ),

        Expanded(
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarDetailsScreen(ownerId: widget.ownerId, existingListing: CarListing.fromJson(car)),
                ),
              );

              if (result == true) fetchCars();
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${car['brand']} ${car['model']}",
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("₱ ${car['price_per_day']}/day",
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  
                  const Spacer(),

                  /// ✅ Now menu is clickable without redirecting
                  Align(
                    alignment: Alignment.bottomRight,
                    child: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.black),
                      onSelected: (value) {
                        if (value == "delete") deleteCar(int.parse(car["id"].toString()));
                        if (value == "edit") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CarDetailsScreen(ownerId: widget.ownerId, existingListing: CarListing.fromJson(car)),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "edit", child: Text("Edit")),
                        PopupMenuItem(value: "delete", child: Text("Delete", style: TextStyle(color: Colors.red))),
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
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .8,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
