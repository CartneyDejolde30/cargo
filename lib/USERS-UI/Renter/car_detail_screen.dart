import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chats/chat_detail_screen.dart';
import 'review_screen.dart';
import '../Renter/bookings/booking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Renter/host/host_profile_screen.dart';

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

  final String baseUrl = "http://192.168.1.11/carGOAdmin/";

  Future<Map<String, String?>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('user_id'),
      'fullName': prefs.getString('fullname'),
      'email': prefs.getString('email'),
      'municipality': prefs.getString('municipality'),
    };
  }

  String formatImage(String path) {
    if (path.isEmpty) return "https://via.placeholder.com/400x300";
    if (path.startsWith("http")) return path;
    return "$baseUrl$path";
  }

  Future<void> fetchCarDetails() async {
    final url = Uri.parse("${baseUrl}api/get_car_details.php?id=${widget.carId}");

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

  Future<void> _callOwner(String number) async {
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No phone number available.")));
      return;
    }

    var permission = await Permission.phone.request();
    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone permission required.")));
      return;
    }

    String formatted = number.replaceAll(RegExp(r'[^0-9+]'), "");

    if (formatted.startsWith("0")) {
      formatted = "+63${formatted.substring(1)}";
    }

    final Uri callUri = Uri.parse("tel:$formatted");

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Cannot open dialer.")));
    }
  }

  void _messageOwner() async {
    if (carData == null) return;

    final userData = await _getUserData();
    final String currentUserId = userData['userId'] ?? "USER123";
    final String ownerId = carData?["owner_id"].toString() ?? "";

    final chatId = (currentUserId.compareTo(ownerId) < 0)
        ? "${currentUserId}_$ownerId"
        : "${ownerId}_$currentUserId";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          peerId: ownerId,
          peerName: carData?["owner_name"] ?? "Unknown",
          peerAvatar: carData?["owner_image"] ?? "",
        ),
      ),
    );
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
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final imageUrl = formatImage(carData?["image"] ?? "");
    final ownerImage = formatImage(carData?["owner_image"] ?? "");
    final ownerName = carData?["owner_name"] ?? "Unknown Owner";
    final phone = carData?["phone"] ?? "";
    final price = carData?["price_per_day"] ?? widget.price;
    final location = carData?["location"] ?? "Unknown";
    final description = carData?["description"] ?? "No description available";
    final features = carData?["features"] != null
        ? List<String>.from(jsonDecode(carData!["features"]))
        : <String>[];
    final rules = carData?["rules"] != null
        ? List<String>.from(jsonDecode(carData!["rules"]))
        : <String>[];
    final seats = carData?["seat"] ?? 4;
    final deliveryTypes = carData?["delivery_types"] != null
        ? List<String>.from(jsonDecode(carData!["delivery_types"]))
        : <String>[];
    final transmission = carData?["transmission"] ?? "Automatic";
    final fuelType = carData?["fuel_type"] ?? "Gasoline";
    final minTripDuration = carData?["min_trip_duration"] ?? "1";
    final maxTripDuration = carData?["max_trip_duration"] ?? "7";
    final advanceNotice = carData?["advance_notice"] ?? "1 hour";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Image with Back Button
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: Container(
                          height: 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Back Button
                      Positioned(
                        top: 16,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Car Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.carName,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.rating}",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on, color: Colors.red, size: 20),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.poppins(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Car Specifications Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Specifications",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildSpecRow(Icons.event_seat, "Seats", "$seats Seater"),
                              const Divider(height: 24),
                              _buildSpecRow(Icons.settings, "Transmission", transmission),
                              const Divider(height: 24),
                              _buildSpecRow(Icons.local_gas_station, "Fuel Type", fuelType),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Rental Information Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rental Information",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.attach_money, color: Colors.green.shade700, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Price per day",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          "₱$price",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.access_time, "Advance Notice", advanceNotice),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.calendar_today, "Min Trip Duration", "$minTripDuration day(s)"),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.event, "Max Trip Duration", "$maxTripDuration day(s)"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Features Section
                  if (features.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Features",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: features.map((feature) {
                              final featureIcon = _getFeatureIcon(feature);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(featureIcon, size: 18, color: Colors.black),
                                    const SizedBox(width: 8),
                                    Text(
                                      feature,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Delivery Options
                  if (deliveryTypes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delivery Options",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...deliveryTypes.map((type) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.local_shipping, size: 20, color: Colors.grey.shade700),
                                  const SizedBox(width: 10),
                                  Text(
                                    type,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Rules Section
                  if (rules.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rules",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...rules.map((rule) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber, size: 20, color: Colors.orange.shade700),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      rule,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Owner Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Car Owner",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HostProfileScreen(
                                  ownerId: carData?["owner_id"].toString() ?? "",
                                  ownerName: ownerName,
                                  ownerImage: carData?["owner_image"] ?? "",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(ownerImage),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ownerName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                  onPressed: _messageOwner,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  onPressed: () => _callOwner(phone),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reviews Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Reviews (${reviews.length})",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reviews.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewsScreen(
                                    carName: widget.carName,
                                    totalReviews: reviews.length,
                                    averageRating: widget.rating,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "See All",
                              style: GoogleFonts.poppins(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  reviews.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "No reviews yet",
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: reviews.take(3).map((review) {
                            return _buildReviewCard(
                              name: review["fullname"] ?? "User",
                              rating: double.tryParse(review["rating"].toString()) ?? 5.0,
                              date: review["created_at"] ?? "",
                              review: review["comment"] ?? "",
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 120),
                ],
              ),
            ),

            // Bottom Action Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(
                            carId: widget.carId,
                            carName: widget.carName,
                            carImage: widget.carImage,
                            pricePerDay: price,
                            location: location,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Book Car",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "₱$price/day",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get feature icon based on feature name
  IconData _getFeatureIcon(String featureName) {
    final featureIcons = {
      'AUX input': Icons.audiotrack,
      'All-wheel drive': Icons.all_inclusive,
      'Android auto': Icons.android,
      'Apple Carplay': Icons.apple,
      'Autosweep': Icons.toll,
      'Backup camera': Icons.videocam,
      'Bike rack': Icons.directions_bike,
      'Blind spot warning': Icons.warning,
      'Bluetooth': Icons.bluetooth,
      'Child seat': Icons.child_care,
      'Convertible': Icons.directions_car,
      'Easytrip': Icons.credit_card,
      'GPS': Icons.gps_fixed,
      'Keyless entry': Icons.vpn_key,
      'Pet-friendly': Icons.pets,
      'Sunroof': Icons.wb_sunny,
      'USB Charger': Icons.usb,
      'USB input': Icons.cable,
      'Wheelchair accessible': Icons.accessible,
    };
    
    return featureIcons[featureName] ?? Icons.check_circle;
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullscreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}