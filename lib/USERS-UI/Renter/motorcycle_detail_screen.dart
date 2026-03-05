import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cargo/config/api_config.dart';
import 'chats/chat_detail_screen.dart';
import 'review_screen.dart';
import '../Reporting/submit_review_screen.dart';  // ⭐ ADDED

import 'package:shared_preferences/shared_preferences.dart';
import '../Renter/host/host_profile_screen.dart';
import 'package:cargo/USERS-UI/Owner/verification/personal_info_screen.dart';
import 'package:cargo/USERS-UI/Reporting/report_screen.dart';
import 'package:cargo/USERS-UI/Renter/bookings/motorcycle_booking_screen.dart';
import 'widgets/renter_availability_calendar.dart'; 
import 'widgets/favorite_button.dart';
import 'package:cargo/widgets/loading_widgets.dart';
import '../../utils/image_helper.dart';
import '../../widgets/optimized_network_image.dart';


class MotorcycleDetailScreen extends StatefulWidget {
  final int motorcycleId;
  final String motorcycleName;
  final String motorcycleImage;
  final String price;
  final double rating;
  final String location;

  const MotorcycleDetailScreen({
    super.key,
    required this.motorcycleId,
    required this.motorcycleName,
    required this.motorcycleImage,
    required this.price,
    required this.rating,
    required this.location,
  });

  @override
  State<MotorcycleDetailScreen> createState() =>
      _MotorcycleDetailScreenState();
}

class _MotorcycleDetailScreenState
    extends State<MotorcycleDetailScreen> {
  bool loading = true;
  Map<String, dynamic>? motorcycleData;
  List<dynamic> reviews = [];

  bool isVerified = false;
  bool isCheckingVerification = true;
  String verificationMessage = '';

  final String baseUrl = GlobalApiConfig.baseUrl + "/";

  Future<Map<String, String?>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('user_id'),
      'fullName': prefs.getString('fullname'),
      'email': prefs.getString('email'),
      'municipality': prefs.getString('municipality'),
    };
  }

  List<String> getAllImages() {
    List<String> images = [];

    // Main image
    if (motorcycleData?["image"] != null && motorcycleData!["image"].toString().isNotEmpty) {
      images.add(formatImage(motorcycleData!["image"]));
    }

    // Extra images
    final extra = motorcycleData?["extra_images"];

    // ✅ FIX: The PHP backend already decodes extra_images as a List
    // No need to jsonDecode again - it's already a List!
    if (extra != null) {
      if (extra is List && extra.isNotEmpty) {
        // Already a List from PHP json_decode
        for (var img in extra) {
          final imgStr = img.toString().trim();
          if (imgStr.isNotEmpty && imgStr != "[]" && imgStr != "null") {
            images.add(formatImage(imgStr));
          }
        }
      } else if (extra is String && extra.isNotEmpty && extra != "[]") {
        // Fallback: if it's still a JSON string (shouldn't happen with new PHP)
        try {
          final decoded = jsonDecode(extra);
          if (decoded is List && decoded.isNotEmpty) {
            for (var img in decoded) {
              final imgStr = img.toString().trim();
              if (imgStr.isNotEmpty && imgStr != "[]" && imgStr != "null") {
                images.add(formatImage(imgStr));
              }
            }
          }
        } catch (e) {
          print("⚠️ Failed to decode extra_images: $e");
        }
      }
    }

    return images;
  }

  String formatImage(String path) {
    return ImageHelper.formatImageUrl(path);
  }

   Future<void> _checkVerificationStatus() async {
    final userData = await _getUserData();
    final userId = userData['userId'];

    if (userId == null || userId.isEmpty) {
      setState(() {
        isCheckingVerification = false;
        isVerified = false;
      });
      return;
    }

    try {
      final url = Uri.parse("${GlobalApiConfig.checkVerificationEndpoint}?user_id=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          isVerified = result['is_verified'] ?? false;
          verificationMessage = result['message'] ?? '';
          isCheckingVerification = false;
        });
      } else {
        setState(() {
          isVerified = false;
          isCheckingVerification = false;
        });
      }
    } catch (e) {
      print("❌ Verification Check Error: $e");
      setState(() {
        isVerified = false;
        isCheckingVerification = false;
      });
    }
  }

Future<void> fetchMotorcycleDetails() async {
  final url = Uri.parse(
    "${baseUrl}api/get_motorcycle_details.php?id=${widget.motorcycleId}",
  );

  try {
    final response = await http.get(url);
    print("📦 Response Body: ${response.body}");

    if (!mounted) return;

    if (response.statusCode != 200 || response.body.isEmpty) {
      setState(() => loading = false);
      return;
    }

    final result = jsonDecode(response.body);

    final bool isSuccess =
        result["status"] == "success" || result["success"] == true;

    final data = result["motorcycle"] ?? result["car"];

    if (isSuccess && data != null) {
      setState(() {
        motorcycleData = data;
        reviews = result["reviews"] ?? [];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  } catch (e) {
    if (!mounted) return;
    print("❌ ERROR FETCHING DETAILS: $e");
    setState(() => loading = false);
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
    if (motorcycleData == null) return;

    final userData = await _getUserData();
    final String currentUserId = userData['userId'] ?? "USER123";
    final String ownerId = motorcycleData?["owner_id"].toString() ?? "";

    final chatId = (currentUserId.compareTo(ownerId) < 0)
        ? "${currentUserId}_$ownerId"
        : "${ownerId}_$currentUserId";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          peerId: ownerId,
          peerName: motorcycleData?["owner_name"] ?? "Unknown",
          peerAvatar: motorcycleData?["owner_image"] ?? "",
        ),
      ),
    );
  }

  // ⭐ NEW METHOD ADDED
  Future<bool> _checkIfUserBookedMotorcycle(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
  "${baseUrl}api/check_user_booking.php?user_id=$userId&car_id=${widget.motorcycleId}",
),

      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['has_booked'] == true;
      }
      return false;
    } catch (e) {
      print("❌ Error checking booking: $e");
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
     print("🏍️ motorcycleId passed: ${widget.motorcycleId}");


    _checkVerificationStatus();
    fetchMotorcycleDetails();
    
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: LoadingScreen(message: 'Loading motorcycle details...'),
      );
    }
 final colors = Theme.of(context).colorScheme;   // ⭐ ADD THIS
  final isDark = Theme.of(context).brightness == Brightness.dark; // ← ONLY HERE
    final images = getAllImages();
    print("🖼 MOTORCYCLE IMAGES: $images");
    if (images.isEmpty) {
      images.add("https://via.placeholder.com/400x300");
    }

    final ownerImage = formatImage(motorcycleData?["owner_image"] ?? "");
    print("🖼️ MOTORCYCLE OWNER IMAGE:");
    print("   Raw from API: ${motorcycleData?["owner_image"]}");
    print("   Owner Name: ${motorcycleData?["owner_name"]}");
    print("   Final URL: $ownerImage");
    
    final ownerName = motorcycleData?["owner_name"] ?? "Unknown Owner";
    final phone = motorcycleData?["phone"] ?? "";
    final price = motorcycleData?["price_per_day"]?.toString() ?? widget.price;

    final double averageRating =
        double.tryParse(motorcycleData?["average_rating"]?.toString() ?? "") ??
            widget.rating;
    final int reviewCount =
        int.tryParse(motorcycleData?["review_count"]?.toString() ?? "") ??
            reviews.length;

    final location = motorcycleData?["location"]?.toString().trim().isNotEmpty == true
    ? motorcycleData!["location"]
    : "Location not set";
    final engineSize = motorcycleData?["engine_displacement"]?.toString() ?? "N/A";
    final bodyStyle = motorcycleData?["body_style"] ?? "Standard";
    final transmission = motorcycleData?["transmission_type"] ?? "Manual";

    final description = motorcycleData?["description"] ?? "No description available";

    final features = motorcycleData?["features"] != null
    ? List<String>.from(motorcycleData!["features"])
    : <String>[];

    final rules = motorcycleData?["rules"] != null
        ? List<String>.from(motorcycleData!["rules"])
        : <String>[];

    final deliveryTypes = motorcycleData?["delivery_types"] != null
        ? List<String>.from(motorcycleData!["delivery_types"])
        : <String>[];

    final minTripDuration = motorcycleData?["min_trip_duration"] ?? "1";
    final maxTripDuration = motorcycleData?["max_trip_duration"] ?? "7";
    final advanceNotice = motorcycleData?["advance_notice"] ?? "1 hour";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      SizedBox(
                        height: 280,
                        child: PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final imgUrl = images[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullscreenImageViewer(imageUrl: imgUrl),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                  image: DecorationImage(
                                    image: ImageHelper.getNetworkImage(imgUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Back Button (LEFT)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back, size: 24),
                          ),
                        ),
                      ),                      // Favorite Button (CENTER RIGHT)
                      Positioned(
                        top: 16,
                        right: 70,
                        child: FavoriteButton(
                          vehicleType: 'motorcycle',
                          vehicleId: widget.motorcycleId,
                          size: 24,
                        ),
                      ),

                      // Report Button (RIGHT)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportScreen(
                                  reportType: 'motorcycle',
                                  reportedId: widget.motorcycleId.toString(),
                                  reportedName: widget.motorcycleName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.flag, size: 24, color: Colors.red.shade600),
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
                          widget.motorcycleName,
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
                              averageRating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            
                          ),
                          child: Column(
                            children: [
                              _buildSpecRow(Icons.speed, "Engine", "$engineSize cc"),
                              _buildSpecRow(Icons.category, "Body Style", bodyStyle),
                              _buildSpecRow(Icons.settings, "Transmission", transmission),

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
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      const SizedBox(height: 12),

      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          
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
                  child: Icon(
                    Icons.payments,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Price per day",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
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

/// DESCRIPTION
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
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDark ? Colors.white70 : Colors.grey.shade700,
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
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                 
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
                                        color: Theme.of(context).iconTheme.color,



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
                                  Icon(Icons.local_shipping, size: 20, color: colors.onSurfaceVariant),
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
                          "Motor Cycle Owner",
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
                                  ownerId: motorcycleData?["owner_id"].toString() ?? "",
                                  ownerName: ownerName,
                                  ownerImage: motorcycleData?["owner_image"] ?? "",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: OptimizedNetworkImage(
                                      imageUrl: ownerImage,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorIcon: Icons.person,
                                      errorIconSize: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ownerName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.chat_bubble_outline, size: 22, color: colors.primary),
                                  onPressed: _messageOwner,
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(),
                                ),
                                IconButton(
                                  icon: Icon(Icons.call, size: 22, color: colors.tertiary),
                                  onPressed: () => _callOwner(phone),
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ⭐ UPDATED REVIEWS SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Reviews ($reviewCount)",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reviews.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewsScreen(
                                    carId: widget.motorcycleId,
                                    carName: widget.motorcycleName,
                                    totalReviews: reviewCount,
                                    averageRating: averageRating,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "See All",
                              style: GoogleFonts.poppins(
                                color: colors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                 Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: OutlinedButton.icon(
    onPressed: () async {
      final userData = await _getUserData();
      final userId = userData['userId'];

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to leave a review'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final hasBooked = await _checkIfUserBookedMotorcycle(userId);

      if (!hasBooked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to complete a booking first'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubmitReviewScreen(
            bookingId: '',
            carId: widget.motorcycleId.toString(),
            carName: widget.motorcycleName,
            carImage: widget.motorcycleImage,
            ownerId: motorcycleData?["owner_id"].toString() ?? "",
            ownerName: motorcycleData?["owner_name"] ?? "Unknown",
            ownerImage: motorcycleData?["owner_image"] ?? "",
          ),
        ),
      ).then((result) {
        if (result == true) {
          fetchMotorcycleDetails();
        }
      });
    },

    icon: Icon(
      Icons.rate_review,
      size: 20,
      color: colors.primary,
    ),

    label: Text(
      'Leave a Review',
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    ),

    style: OutlinedButton.styleFrom(
      side: BorderSide(color: colors.primary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

                  const SizedBox(height: 16),

                  // Continue with existing reviews display...
                  reviews.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
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
                              name: review["reviewer_name"] ??
                                  review["name"] ??
                                  review["fullname"] ??
                                  "User",
                              avatarUrl: review["reviewer_image"] ??
                                  review["avatar"] ??
                                  "",
                              rating: double.tryParse(review["rating"].toString()) ?? 5.0,
                              date: review["created_at"] ?? "",
                              review: review["review"] ??
                                  review["comment"] ??
                                  "",
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 180), // ✅ Increased to prevent underlapping with bottom buttons
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
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // NEW: Check Availability Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RenterAvailabilityCalendar(
                                  vehicleId: widget.motorcycleId,
                                  vehicleType: 'motorcycle',
                                  vehicleName: widget.motorcycleName,
                                ),
                              ),
                            );
                            
                            // If dates selected, proceed to booking
                            if (result != null && result is Map) {
                              if (!isVerified) {
                                _showVerificationRequiredDialog();
                                return;
                              }
                              
                              final userData = await _getUserData();
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: 'motorcycle'),
                                    builder: (_) => MotorcycleBookingScreen(
                                      motorcycleId: widget.motorcycleId,
                                      motorcycleName: widget.motorcycleName,
                                      motorcycleImage: widget.motorcycleImage,
                                      pricePerDay: price,
                                      location: location,
                                      ownerId: motorcycleData?["owner_id"]?.toString() ?? "",
                                      userId: userData['userId'],
                                      userFullName: userData['fullName'],
                                      userEmail: userData['email'],
                                      userContact: userData['contact'],
                                      userMunicipality: userData['municipality'],
                                      ownerLatitude: double.tryParse(
                                        motorcycleData?["latitude"]?.toString() ?? "",
                                      ),
                                      ownerLongitude: double.tryParse(
                                        motorcycleData?["longitude"]?.toString() ?? "",
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.calendar_month, size: 20),
                          label: Text(
                            'Check Availability',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(color: colors.primary, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Existing Book Now Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isCheckingVerification 
                              ? null 
                              : (isVerified 
                                  ? () async {
                                      final userData = await _getUserData();  

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        settings: const RouteSettings(name: 'motorcycle'),
                                        builder: (_) => MotorcycleBookingScreen(
                                          motorcycleId: widget.motorcycleId,
                                          motorcycleName: widget.motorcycleName,
                                          motorcycleImage: widget.motorcycleImage,
                                          pricePerDay: price,
                                          location: location,
                                          ownerId: motorcycleData?["owner_id"]?.toString() ?? "",
                                          userId: userData['userId'],
                                          userFullName: userData['fullName'],
                                          userEmail: userData['email'],
                                          userContact: userData['contact'],
                                          userMunicipality: userData['municipality'],
                                          ownerLatitude: double.tryParse(
                                            motorcycleData?["latitude"]?.toString() ?? "",
                                          ),
                                          ownerLongitude: double.tryParse(
                                            motorcycleData?["longitude"]?.toString() ?? "",
                                          ),
                                        ),
                                      ),
                                    );

                                    }
                                  : () {
                                      _showVerificationRequiredDialog();
                                    }
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCheckingVerification 
                                ? Colors.grey.shade400
                                : (isVerified ? Colors.black : Colors.grey.shade600),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                       child: Center(
  child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    /// LEFT — icon + text centered together
    Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCheckingVerification)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else if (!isVerified)
            const Icon(Icons.lock, size: 20, color: Colors.white),

          if (isCheckingVerification || !isVerified)
            const SizedBox(width: 8),

          Text(
            isCheckingVerification
                ? "Checking..."
                : (isVerified ? "Book Motorcycle" : "Verification Required"),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),

    /// RIGHT — price badge (only when verified)
    if (isVerified && !isCheckingVerification)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFeatureIcon(String featureName) {
  final name = featureName.toLowerCase();

  // Motorcycle-specific features
  if (name.contains('abs')) return Icons.security;
  if (name.contains('disc brake')) return Icons.stop_circle;
  if (name.contains('drum brake')) return Icons.circle;
  if (name.contains('electric start')) return Icons.flash_on;
  if (name.contains('kick start')) return Icons.directions_run;
  if (name.contains('fuel injection')) return Icons.local_gas_station;
  if (name.contains('carburetor')) return Icons.settings;
  if (name.contains('digital meter')) return Icons.speed;
  if (name.contains('analog meter')) return Icons.speed_outlined;
  if (name.contains('led')) return Icons.lightbulb;
  if (name.contains('halogen')) return Icons.lightbulb_outline;
  if (name.contains('alloy wheel')) return Icons.album;
  if (name.contains('spoke wheel')) return Icons.radio_button_unchecked;
  if (name.contains('top box')) return Icons.inventory_2;
  if (name.contains('side mirror')) return Icons.visibility;
  if (name.contains('crash guard')) return Icons.shield;
  if (name.contains('anti theft')) return Icons.lock;
  if (name.contains('usb charger')) return Icons.usb;
  if (name.contains('gps')) return Icons.gps_fixed;

  // Riding & comfort
  if (name.contains('comfortable seat')) return Icons.event_seat;
  if (name.contains('windshield')) return Icons.air;
  if (name.contains('heated grips')) return Icons.wb_sunny;

  // Documents / legality
  if (name.contains('registered')) return Icons.assignment_turned_in;
  if (name.contains('insured')) return Icons.verified;

  // Default fallback
  return Icons.check_circle;
}


  Widget _buildSpecRow(IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 24, color: colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.black : colors.onSurfaceVariant,

            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).iconTheme.color,



          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Row(
    children: [
      Icon(icon, size: 20, color: Colors.blue.shade700),
      const SizedBox(width: 12),

      Expanded(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
      ),

      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    ],
  );
}


  String _formatRelativeDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          if (diff.inMinutes <= 1) return "Just now";
          return "${diff.inMinutes} mins ago";
        }
        return "${diff.inHours} hours ago";
      }
      if (diff.inDays == 1) return "Yesterday";
      if (diff.inDays < 7) return "${diff.inDays} days ago";
      if (diff.inDays < 30) return "${(diff.inDays / 7).floor()} weeks ago";
      return "${(diff.inDays / 30).floor()} months ago";
    } catch (_) {
      return dateString;
    }
  }

  Widget _buildReviewCard({
    required String name,
    required String avatarUrl,
    required double rating,
    required String date,
    required String review,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: avatarUrl.isNotEmpty
                    ? ImageHelper.getNetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 18, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatRelativeDate(date),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark
                                ? colors.onSurfaceVariant
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? colors.onSurfaceVariant : Colors.grey.shade700,
              height: 1.4,
            ),
            maxLines: null, // ✅ Allow unlimited lines to show full review
            overflow: TextOverflow.visible, // ✅ Don't truncate the text
          ),
        ],
      ),
    );
  }

  void _showVerificationRequiredDialog() {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.verified_user, color: Colors.orange.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verification Required',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verificationMessage.isEmpty
                  ? 'You need to verify your account before booking a Motorcycle.'
                  : verificationMessage,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verification takes 24-48 hours',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: colors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalInfoScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary
,







              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Get Verified',
              style: GoogleFonts.poppins(
                color: colors.surface,
                fontWeight: FontWeight.w600,
              ),
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
          child: ImageHelper.buildMotorcycleImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

