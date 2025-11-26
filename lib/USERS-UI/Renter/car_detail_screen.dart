import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'review_screen.dart';

class CarDetailScreen extends StatefulWidget {
  final int carId;
  final String carName;
  final String carImage;
  final String price;
  final double rating;
  final String location;

  const CarDetailScreen({
    super.key,
    required this.carId,
    required this.carName,
    required this.carImage,
    required this.price,
    required this.rating,
    required this.location,
  });

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  bool loading = true;
  Map<String, dynamic>? carData;
  List<dynamic> reviews = [];

  /// 🔧 Fixes actual image path format
  String formatImage(String rawPath) {
    if (rawPath.isEmpty) {
      return "https://via.placeholder.com/400x300";
    }

    rawPath = rawPath.replaceFirst("uploads/", "");

    return "http://10.72.15.180/carGOAdmin/uploads/$rawPath";
  }

  Future<void> fetchCarDetails() async {
    final url = Uri.parse("http://10.72.15.180/carGOAdmin/api/get_car_details.php?id=${widget.carId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result["status"] == "success") {
          setState(() {
            carData = result["car"];
            reviews = result["reviews"];
            loading = false;
          });
        }
      }
    } catch (e) {
      print("❌ ERROR FETCHING DETAILS: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCarDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// 🧠 Ensure values do not crash app if missing
    final imageUrl = formatImage(carData?["image"] ?? "");
    final ownerImage = formatImage(carData?["owner_image"] ?? "");
    final ownerName = carData?["owner_name"] ?? "Unknown Owner";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  /// 🔥 Main DB Image (Replaces static image)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Image.network(
                      imageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 120),
                    ),
                  ),

                  // 🔥 Owner Details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(ownerImage),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          ownerName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Reviews Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Reviews", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ReviewsScreen(
                                carName: widget.carName,
                                totalReviews: reviews.length,
                                averageRating: widget.rating,
                              ),
                            ));
                          },
                          child: Text("See All", style: GoogleFonts.poppins(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 🔥 Dynamic Review Cards
                  reviews.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text("No reviews yet", style: GoogleFonts.poppins(color: Colors.grey)),
                        )
                      : Column(
                          children: reviews.map((review) {
                            return _buildReviewCard(
                              name: review["fullname"] ?? "User",
                              rating: double.tryParse(review["rating"].toString()) ?? 5.0,
                              date: review["created_at"] ?? "",
                              review: review["comment"] ?? "",
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            /// BOOK NOW (UI unchanged)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Book Now", style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 Same UI Style Review Card (unchanged)
  Widget _buildReviewCard({
    required String name,
    required double rating,
    required String date,
    required String review,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(review, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }
}
