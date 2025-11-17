import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'car_listing/car_details.dart';
import 'models/car_listing.dart';

class MyCarPage extends StatefulWidget {
  final int ownerId;
  const MyCarPage({super.key, required this.ownerId});

  @override
  State<MyCarPage> createState() => _MyCarPageState();
}

class _MyCarPageState extends State<MyCarPage> {
  final String apiUrl = "http://172.31.51.180/carGOAdmin/cars_api.php";
  List<Map<String, dynamic>> cars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCars();
  }

  Future<void> fetchCars() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("$apiUrl?owner_id=${widget.ownerId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          cars = List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> deleteCar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Car"),
        content: const Text("Are you sure you want to delete this car?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"action": "delete", "id": id.toString()},
      );

      final result = jsonDecode(response.body);

      if (result["success"] == true) {
        fetchCars();
      } else {
        showMessage(result["message"] ?? "Failed to delete");
      }
    } catch (e) {
      showMessage("Connection error: $e");
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? resolveImage(String? path) {
    if (path == null || path.isEmpty) return null;
    return "http://172.31.51.180/carGOAdmin/$path";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cars"),
        backgroundColor: Colors.blue,
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CarDetailsScreen(ownerId: widget.ownerId),
            ),
          );
          if (result == true) fetchCars();
        },
      ),

      body: RefreshIndicator(
        onRefresh: fetchCars,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : cars.isEmpty
                ? const Center(child: Text("No cars added yet"))
                : ListView.builder(
                    itemCount: cars.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, index) {
                      final car = cars[index];
                      final imageUrl = resolveImage(car["image"]);
                      final price = car["price_per_day"] ?? "0";

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),

                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl != null
                                ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                                : const Icon(Icons.directions_car, size: 40),
                          ),

                          title: Text(
                            "${car['brand']} ${car['model']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Text(
                            "₱$price/day • ${car['status']}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),

                          trailing: PopupMenuButton(
                            onSelected: (value) async {
                              if (value == "delete") {
                                await deleteCar(int.parse(car["id"].toString()));
                              } else if (value == "edit") {
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
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: "edit", child: Text("Edit")),
                              PopupMenuItem(value: "delete", child: Text("Delete")),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
