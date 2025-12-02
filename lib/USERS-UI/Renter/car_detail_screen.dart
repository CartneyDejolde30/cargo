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

  final String baseUrl = "http://10.72.15.180/carGOAdmin/";

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

  // 📞 CALL OWNER
  Future<void> _callOwner(String number) async {
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No phone number available.")));
      return;
    }

    var permission = await Permission.phone.request();
    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone permission required.")));
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
          .showSnackBar(SnackBar(content: Text("Cannot open dialer.")));
    }
  }

  // 💬 MESSAGE OWNER (NOW FUNCTIONAL)
  void _messageOwner() {
  if (carData == null) return;

  final String currentUserId = "USER123"; // TODO: Replace with real logged-in user
  final String ownerId = carData?["owner_id"].toString() ?? "";

  // Generate a unique chat ID based on both user IDs
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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final imageUrl = formatImage(carData?["image"] ?? "");
    final ownerImage = formatImage(carData?["owner_image"] ?? "");
    final ownerName = carData?["owner_name"] ?? "Unknown Owner";
    final phone = carData?["phone"] ?? "";
    final price = carData?["price_per_day"] ?? widget.price;
    final location = carData?["location"] ?? "Unknown";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: Image.network(
                        imageUrl,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.carName,
                            style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text("₱$price/day",
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.green)),
                        SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.orange),
                            Text("${widget.rating}  |  ",
                                style: GoogleFonts.poppins(fontSize: 14)),
                            Icon(Icons.location_on, color: Colors.red),
                            Text(location,
                                style: GoogleFonts.poppins(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 👤 OWNER + ACTION BUTTONS
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(radius: 26, backgroundImage: NetworkImage(ownerImage)),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  ownerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chat_bubble_outline, color: Colors.blue),
                              onPressed: _messageOwner,
                            ),
                            IconButton(
                              icon: Icon(Icons.call, color: Colors.green),
                              onPressed: () => _callOwner(phone),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Reviews",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold)),
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
                          child: Text("See All",
                              style: GoogleFonts.poppins(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  reviews.isEmpty
                      ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("No reviews yet",
                        style: GoogleFonts.poppins(color: Colors.grey)),
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

                  SizedBox(height: 120),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
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
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Book Now",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildReviewCard({
    required String name,
    required double rating,
    required String date,
    required String review,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(review, style: GoogleFonts.poppins(fontSize: 13)),
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
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
