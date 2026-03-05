import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:cargo/config/api_config.dart';
import '../car_detail_screen.dart';
import '../motorcycle_detail_screen.dart';
import 'package:cargo/widgets/loading_widgets.dart';

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
  List<Map<String, dynamic>> motorcycles = [];
  String selectedTab = 'cars'; // 'cars' or 'motorcycles'

  final String baseUrl = GlobalApiConfig.baseUrl + "/";

  @override
  void initState() {
    super.initState();
    fetchOwnerVehicles();
  }

  String formatImage(String path) {
    if (path.isEmpty) return "https://via.placeholder.com/300";
    if (path.startsWith("http")) return path;
    
    // ✅ Better image cleaning
    String cleanPath = path.replaceAll(RegExp(r'uploads/+'), '');
    return "${baseUrl}uploads/$cleanPath";
  }

  Future<void> fetchOwnerVehicles() async {
  setState(() => loading = true);

  final carsUrl = Uri.parse("${baseUrl}api/get_owner_cars.php?owner_id=${widget.ownerId}");
  final motorcyclesUrl = Uri.parse("${baseUrl}api/get_owner_motorcycles.php?owner_id=${widget.ownerId}");

  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  print("🔍 FETCHING OWNER VEHICLES (Cars & Motorcycles)");
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  print("Owner ID: ${widget.ownerId}");
  print("Cars URL: $carsUrl");
  print("Motorcycles URL: $motorcyclesUrl");
  
  try {
    // Fetch both cars and motorcycles in parallel
    final responses = await Future.wait([
      http.get(carsUrl),
      http.get(motorcyclesUrl),
    ]);

    final carsResponse = responses[0];
    final motorcyclesResponse = responses[1];

    print("📡 Cars Response Status: ${carsResponse.statusCode}");
    print("📦 Cars Response Body: ${carsResponse.body}");
    print("📡 Motorcycles Response Status: ${motorcyclesResponse.statusCode}");
    print("📦 Motorcycles Response Body: ${motorcyclesResponse.body}");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    if (carsResponse.statusCode == 200) {
      final result = jsonDecode(carsResponse.body);
      if (result["status"] == "success") {
        cars = List<Map<String, dynamic>>.from(result["cars"] ?? []);
        print("✅ Loaded ${cars.length} cars for owner ${widget.ownerId}");
      }
    }

    if (motorcyclesResponse.statusCode == 200) {
      final result = jsonDecode(motorcyclesResponse.body);
      if (result["status"] == "success") {
        motorcycles = List<Map<String, dynamic>>.from(result["motorcycles"] ?? []);
        print("✅ Loaded ${motorcycles.length} motorcycles for owner ${widget.ownerId}");
      }
    }
  } catch (e) {
    print("❌ ERROR: $e");
  }

  setState(() => loading = false);
}

  @override
  Widget build(BuildContext context) {
    // final totalVehicles = selectedTab == 'cars' ? cars.length : motorcycles.length; // Unused
    final currentList = selectedTab == 'cars' ? cars : motorcycles;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.ownerName}'s Vehicles",
              style: GoogleFonts.poppins(
                color: Theme.of(context).iconTheme.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!loading)
              Text(
                "${cars.length} car${cars.length != 1 ? 's' : ''} · ${motorcycles.length} motorcycle${motorcycles.length != 1 ? 's' : ''}",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Tab selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 'cars'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTab == 'cars' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selectedTab == 'cars'
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 20,
                            color: selectedTab == 'cars' ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Cars (${cars.length})",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: selectedTab == 'cars' ? FontWeight.w600 : FontWeight.w500,
                              color: selectedTab == 'cars' ? Colors.black : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 'motorcycles'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTab == 'motorcycles' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selectedTab == 'motorcycles'
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.two_wheeler,
                            size: 20,
                            color: selectedTab == 'motorcycles' ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Motorcycles (${motorcycles.length})",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: selectedTab == 'motorcycles' ? FontWeight.w600 : FontWeight.w500,
                              color: selectedTab == 'motorcycles' ? Colors.black : Colors.grey,
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
          
          // Vehicle list
          Expanded(
            child: loading
                ? const LoadingScreen(message: 'Loading vehicles...')
                : currentList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: fetchOwnerVehicles,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            final vehicle = currentList[index];
                            return FadeInUp(
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              child: selectedTab == 'cars'
                                  ? _buildCarCard(vehicle, index)
                                  : _buildMotorcycleCard(vehicle, index),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final vehicleType = selectedTab == 'cars' ? 'cars' : 'motorcycles';
    final icon = selectedTab == 'cars' ? Icons.directions_car_outlined : Icons.two_wheeler_outlined;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No $vehicleType available",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This owner hasn't listed any $vehicleType yet",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car, int index) {
    final imageUrl = formatImage(car['image'] ?? "");
    final carName = "${car['brand'] ?? 'Unknown'} ${car['model'] ?? 'Car'}";
    final year = car['car_year'] ?? "";
    final rating = double.tryParse(car['rating']?.toString() ?? "5.0") ?? 5.0;
    
    // ✅ Better location handling
    final location = (car['location']?.toString().isNotEmpty ?? false) 
        ? car['location'] 
        : "Agusan del Sur";
    
    // ✅ Better price handling
    final price = car['price']?.toString() ?? 
                  car['price_per_day']?.toString() ?? 
                  "0";
    
    final seats = int.tryParse(
      car['seat']?.toString() ?? 
      car['seats']?.toString() ?? 
      "4"
    ) ?? 4;
    
    final hasUnlimitedMileage = (car['has_unlimited_mileage']?.toString() == "1");
    final carId = int.tryParse(car['id']?.toString() ?? "0") ?? 0;

    return GestureDetector(
      onTap: () {
        // ✅ Add validation
        if (carId <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid car data")),
          );
          return;
        }

        print("🚗 Navigating to car: $carName (ID: $carId)");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarDetailScreen(
              carId: carId,
              carName: carName,
              carImage: imageUrl,
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).iconTheme.color,



                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Unlimited mileage badge
                if (hasUnlimitedMileage)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Unlimited",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Car Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      "₱$price/day",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Car name and year
                    Text(
                      year.isNotEmpty ? "$carName $year" : carName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 11, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    const Spacer(),

                    // Seats info
                    Row(
                      children: [
                        Icon(Icons.event_seat, size: 11, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          "$seats-seater",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
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

  Widget _buildMotorcycleCard(Map<String, dynamic> motorcycle, int index) {
    final imageUrl = formatImage(motorcycle['image'] ?? "");
    final motorcycleName = "${motorcycle['brand'] ?? 'Unknown'} ${motorcycle['model'] ?? 'Motorcycle'}";
    final year = motorcycle['year'] ?? "";
    final rating = double.tryParse(motorcycle['rating']?.toString() ?? "5.0") ?? 5.0;
    
    final location = (motorcycle['location']?.toString().isNotEmpty ?? false) 
        ? motorcycle['location'] 
        : "Agusan del Sur";
    
    final price = motorcycle['price']?.toString() ?? 
                  motorcycle['price_per_day']?.toString() ?? 
                  "0";
    
    final hasUnlimitedMileage = (motorcycle['has_unlimited_mileage']?.toString() == "1");
    final motorcycleId = int.tryParse(motorcycle['id']?.toString() ?? "0") ?? 0;
    final engineSize = motorcycle['engine_size'] ?? motorcycle['engine_capacity'] ?? "";

    return GestureDetector(
      onTap: () {
        if (motorcycleId <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid motorcycle data")),
          );
          return;
        }

        print("🏍️ Navigating to motorcycle: $motorcycleName (ID: $motorcycleId)");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MotorcycleDetailScreen(
              motorcycleId: motorcycleId,
              motorcycleName: motorcycleName,
              motorcycleImage: imageUrl,
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motorcycle Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).iconTheme.color,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.two_wheeler,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Unlimited mileage badge
                if (hasUnlimitedMileage)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Unlimited",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Motorcycle Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      "₱$price/day",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Motorcycle name and year
                    Text(
                      year.isNotEmpty ? "$motorcycleName $year" : motorcycleName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 11, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    const Spacer(),

                    // Engine size info
                    if (engineSize.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.speed, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            "$engineSize cc",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
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