import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_config.dart';

import '../Renter/widgets/bottom_nav_bar.dart';
import 'car_list_screen.dart';
import '../Renter/chats/chat_list_screen.dart';
import 'motorcycle_detail_screen.dart';
import 'motorcycle_list_screen.dart';

class MotorcycleScreen extends StatefulWidget {
  const MotorcycleScreen({super.key});

  @override
  State<MotorcycleScreen> createState() => _MotorcycleScreenState();
}

class _MotorcycleScreenState extends State<MotorcycleScreen> {
  int _selectedNavIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _motorcycles = [];
  final Map<String, String> _resolvedImageCache = {};

  @override
  void initState() {
    super.initState();
    fetchMotorcycles();
  }

  String formatImage(String? rawPath) {
    final path = rawPath?.toString().trim() ?? '';
    if (path.isEmpty) return "https://via.placeholder.com/300";
    if (path.startsWith("http://") || path.startsWith("https://")) return path;
    final cleanPath = path.replaceFirst("uploads/", "");
    return GlobalApiConfig.getImageUrl(cleanPath);
  }

  Future<String> resolveImageUrlCached(String? rawPath) async {
    const placeholder = "https://via.placeholder.com/400x250?text=No+Image";
    final path = rawPath?.toString().trim() ?? '';
    if (path.isEmpty) return placeholder;

    String candidate;
    if (path.startsWith("http://") || path.startsWith("https://")) {
      candidate = path;
    } else {
      final clean = path.replaceFirst("uploads/", "");
      candidate = GlobalApiConfig.getImageUrl(clean);
    }

    if (_resolvedImageCache.containsKey(candidate)) return _resolvedImageCache[candidate]!;

    try {
      final resp = await http.head(Uri.parse(candidate)).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        _resolvedImageCache[candidate] = candidate;
        return candidate;
      }
    } catch (_) {}

    _resolvedImageCache[candidate] = placeholder;
    return placeholder;
  }

  Future<void> fetchMotorcycles() async {
    final String apiUrl = "${GlobalApiConfig.getMotorcyclesFilteredEndpoint}?sortBy=created_at&sortOrder=DESC";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      print("🔍 API Response Status: ${response.statusCode}");
      print("🔍 API Response Body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['status'] == 'success') {
          setState(() {
            _motorcycles = List<Map<String, dynamic>>.from(decoded['motorcycles']);
          });
          print("✅ Loaded ${_motorcycles.length} motorcycles");
        } else if (decoded['status'] == 'error') {
          print("❌ API Error: ${decoded['message']}");
        }
      }
    } catch (e) {
      print("❌ Error fetching motorcycles: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _handleNavigation(int index) {
    setState(() => _selectedNavIndex = index);

    switch (index) {
      case 0:
        Navigator.pop(context); // Back to home (cars)
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CarListScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get best motorcycles (first 4) and newly listed (last 3)
    final bestMotorcycles = _motorcycles.take(4).toList();
    final newlyListed = _motorcycles.length > 3 ? _motorcycles.skip(_motorcycles.length - 3).toList() : _motorcycles;
  final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CARGO - Motorcycles",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar - Navigate to list screen
               // Search Bar - Navigate to list screen
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MotorcycleListScreen(),
      ),
    );
  },
  child: Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Search motorcycle near you...",
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  ),
),

                const SizedBox(height: 20),

                // Vehicle Type Toggle
                _buildVehicleTypeToggle(),
                const SizedBox(height: 20),

                // Best Motorcycles Section
                _buildSectionHeader("Best Motorcycles", "View All"),
                const SizedBox(height: 8),
                Text(
  "Available",
  style: GoogleFonts.poppins(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
),
                const SizedBox(height: 12),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _motorcycles.isEmpty
                        ? const Center(child: Text("No motorcycles available"))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: bestMotorcycles.length,
                            itemBuilder: (context, index) {
                              final motorcycle = bestMotorcycles[index];

                              final rawLocation = (motorcycle['location'] ?? '').toString().trim();
                              final locationText = rawLocation.isEmpty ? "Unknown" : rawLocation;

                              return _buildMotorcycleCard(
                                motorcycleId: int.tryParse(motorcycle['id'].toString()) ?? 0,
                                image: formatImage(motorcycle['image'] ?? ''),
                                name: "${motorcycle['brand']} ${motorcycle['model']}",
                                rating: double.tryParse(motorcycle['rating'].toString()) ?? 5.0,
                                location: locationText,
                                type: motorcycle['body_style'] ?? motorcycle['type'] ?? "Standard",
                                price: motorcycle['price'].toString(),
                              );
                            },
                          ),

                const SizedBox(height: 32),

                // Newly Listed Section
                _buildSectionHeader("Newly Listed", "See more", color: Colors.green),
                const SizedBox(height: 12),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : newlyListed.isEmpty
                        ? const Center(child: Text("No new listings"))
                        : SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: newlyListed.length,
                              itemBuilder: (context, index) {
                                final motorcycle = newlyListed[index];

                                final rawLocation = (motorcycle['location'] ?? '').toString().trim();
                                final locationText = rawLocation.isEmpty ? "Unknown" : rawLocation;

                                return _buildNewlyListedCard(
                                  motorcycleId: int.tryParse(motorcycle['id'].toString()) ?? 0,
                                  image: formatImage(motorcycle['image'] ?? ''),
                                  name: "${motorcycle['brand']} ${motorcycle['model']}",
                                  year: motorcycle['motorcycle_year'] ?? "",
                                  location: locationText,
                                  type: motorcycle['body_style'] ?? motorcycle['type'] ?? "Standard",
                                  transmission: motorcycle['transmission_type'] ?? motorcycle['transmission'] ?? "Manual",
                                  price: motorcycle['price'].toString(),
                                  hasUnlimitedMileage: motorcycle['has_unlimited_mileage'] == 1,
                                );
                              },
                            ),
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

  Widget _buildSectionHeader(String title, String action, {Color color = Colors.grey}) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: colors.onSurface,
),

        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MotorcycleListScreen(),
              ),
            );
          },
          child: Text(
            action,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeToggle() {
  final colors = Theme.of(context).colorScheme;

  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest, // ✅ correct soft background
      borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            "Car",
            false,
            () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: _buildToggleButton(
            "Motorcycle",
            true,
            () {},
          ),
        ),
      ],
    ),
  );
}

  Widget _buildMotorcycleCard({
    
    required int motorcycleId,
    required String image,
    required String name,
    required double rating,
    required String location,
    required String type,
    required String price,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MotorcycleDetailScreen(
              motorcycleId: motorcycleId,
              motorcycleName: name,
              motorcycleImage: image,
              price: price,
              rating: rating,
              location: location,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: FutureBuilder<String>(
                future: resolveImageUrlCached(image),
                builder: (context, snap) {
                  final imageUrl = snap.data ?? "https://via.placeholder.com/400x250?text=No+Image";
                  return Image.network(
                    imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 110,
                        color: Theme.of(context).colorScheme.onSurface,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color: Theme.of(context).colorScheme.onSurface,
                      child: const Icon(Icons.two_wheeler, size: 60, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        type,
                        style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₱$price/day",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewlyListedCard({
    required int motorcycleId,
    required String image,
    required String name,
    required String year,
    required String location,
    required String type,
    required String transmission,
    required String price,
    bool hasUnlimitedMileage = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MotorcycleDetailScreen(
              motorcycleId: motorcycleId,
              motorcycleName: name,
              motorcycleImage: image,
              price: price,
              rating: 5.0,
              location: location,
            ),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: FutureBuilder<String>(
                    future: resolveImageUrlCached(image),
                    builder: (context, snap) {
                      final imageUrl = snap.data ?? "https://via.placeholder.com/400x250?text=No+Image";
                      return Image.network(
                        imageUrl,
                        height: 160,
                        width: 140,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 160,
                            width: 140,
                            color: Theme.of(context).colorScheme.onSurface,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          width: 140,
                          color: Theme.of(context).colorScheme.onSurface,
                          child: const Icon(Icons.two_wheeler, size: 40, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                if (hasUnlimitedMileage)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Unlimited Mileage",
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).iconTheme.color,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "₱$price",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$name $year",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        Icon(Icons.category, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.speed, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            transmission,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

 Widget _buildToggleButton(String label, bool selected, VoidCallback onTap) {
  final colors = Theme.of(context).colorScheme;

  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? colors.onSurface : colors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

}

/*
// Unused helper methods - kept for reference if needed later

  Widget _buildSectionHeader(String title, String action, {Color color = Colors.grey}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CarListScreen()),
          ),
          child: Text(
            action,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewlyListedCard({
    required int motorcycleId,
    required String image,
    required String name,
    required String year,
    required String location,
    required String type,
    required String price,
    required String engineSize,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MotorcycleDetailScreen(
              motorcycleId: motorcycleId,
              motorcycleName: name,
              motorcycleImage: image,
              price: price,
              rating: 5.0,
              location: location,
            ),

          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: FutureBuilder<String>(
                future: resolveImageUrlCached(image),
                builder: (context, snap) {
                  final imageUrl = snap.data ?? "https://via.placeholder.com/400x250?text=No+Image";
                  return Image.network(
                    imageUrl,
                    height: 160,
                    width: 140,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        width: 140,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.two_wheeler, size: 40, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "₱$price",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).iconTheme.color,



                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$name $year",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,

                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
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
                        Icon(Icons.category, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.speed, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            engineSize,
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
*/
