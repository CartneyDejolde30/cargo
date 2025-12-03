import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../car_detail_screen.dart';

class HostCarsScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;

  const HostCarsScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<HostCarsScreen> createState() => _HostCarsScreenState();
}

class _HostCarsScreenState extends State<HostCarsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> cars = [];

  final String baseUrl = "http://192.168.1.11/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    fetchOwnerCars();
  }

  String formatImage(String path) {
    if (path.isEmpty) return "https://via.placeholder.com/300";
    if (path.startsWith("http")) return path;
    return "$baseUrl$path";
  }

  Future<void> fetchOwnerCars() async {
    final url = Uri.parse("${baseUrl}api/get_owner_cars.php?owner_id=${widget.ownerId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result["status"] == "success") {
          setState(() {
            cars = List<Map<String, dynamic>>.from(result["cars"]);
            loading = false;
          });
        }
      }
    } catch (e) {
      print("❌ ERROR FETCHING OWNER CARS: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.ownerName}'s Cars",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${cars.length} vehicle${cars.length != 1 ? 's' : ''}",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : cars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No cars available",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    return _buildCarCard(
                      carId: int.tryParse(car['id'].toString()) ?? 0,
                      image: formatImage(car['image'] ?? ""),
                      name: "${car['brand']} ${car['model']}",
                      year: car['car_year'] ?? "",
                      rating: double.tryParse(car['rating'].toString()) ?? 5.0,
                      location: car['location'].isEmpty ? "Unknown" : car['location'],
                      price: car['price_per_day'].toString(),
                      seats: int.tryParse(car['seat'].toString()) ?? 4,
                      transmission: car['transmission'] ?? "Automatic",
                      hasUnlimitedMileage: car['has_unlimited_mileage'] == 1,
                    );
                  },
                ),
    );
  }

  Widget _buildCarCard({
    required int carId,
    required String image,
    required String name,
    required String year,
    required double rating,
    required String location,
    required String price,
    required int seats,
    required String transmission,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "₱$price",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
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