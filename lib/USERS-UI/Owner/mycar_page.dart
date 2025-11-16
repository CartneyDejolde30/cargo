import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class MyCarPage extends StatefulWidget {
  final int ownerId;
  const MyCarPage({super.key, required this.ownerId});

  @override
  State<MyCarPage> createState() => _MyCarPageState();
}

class _MyCarPageState extends State<MyCarPage> {
  final String apiUrl = "http://192.168.1.29/carGOAdmin/my_car/cars_api.php";
  List cars = [];

  @override
  void initState() {
    super.initState();
    fetchCars();
  }

  Future<void> fetchCars() async {
    final response = await http.get(Uri.parse("$apiUrl?owner_id=${widget.ownerId}"));
    if (response.statusCode == 200) {
      setState(() {
        cars = json.decode(response.body);
      });
    }
  }

  Future<void> addOrEditCar({Map? car}) async {
    final picker = ImagePicker();
    File? imageFile;
    final nameController = TextEditingController(text: car?['car_name'] ?? '');
    final brandController = TextEditingController(text: car?['brand'] ?? '');
    final modelController = TextEditingController(text: car?['model'] ?? '');
    final plateController = TextEditingController(text: car?['plate_number'] ?? '');
    final priceController = TextEditingController(text: car?['price_per_day'] ?? '');
    String status = car?['status'] ?? 'Available';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(car == null ? "Add Car" : "Edit Car"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setStateDialog(() => imageFile = File(picked.path));
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      image: imageFile != null
                          ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
                          : (car?['image'] != null && car!['image'] != "")
                              ? DecorationImage(
                                  image: NetworkImage("http://10.122.38.180/carGOAdmin/my_car/${car['image']}"),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: imageFile == null && (car?['image'] == null || car!['image'] == "")
                        ? const Center(child: Text("Tap to upload image"))
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Car Name")),
                TextField(controller: brandController, decoration: const InputDecoration(labelText: "Brand")),
                TextField(controller: modelController, decoration: const InputDecoration(labelText: "Model")),
                TextField(controller: plateController, decoration: const InputDecoration(labelText: "Plate Number")),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price per Day")),
                DropdownButtonFormField(
                  value: status,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: ['Available', 'Booked', 'Pending']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => status = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
                request.fields['owner_id'] = widget.ownerId.toString();
                request.fields['car_name'] = nameController.text;
                request.fields['brand'] = brandController.text;
                request.fields['model'] = modelController.text;
                request.fields['plate_number'] = plateController.text;
                request.fields['price_per_day'] = priceController.text;
                request.fields['status'] = status;

                if (imageFile != null) {
                  request.files.add(await http.MultipartFile.fromPath('image', imageFile!.path));
                }

                final res = await request.send();
                if (res.statusCode == 200) {
                  Navigator.pop(context);
                  fetchCars();
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteCar(int id) async {
    final confirm = await showDialog(
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

    if (confirm == true) {
      await http.delete(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id.toString()},
      );
      fetchCars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Cars"), backgroundColor: Colors.blue),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditCar(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: fetchCars,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cars.length,
          itemBuilder: (context, index) {
            final car = cars[index];
            return Card(
              child: ListTile(
                leading: car['image'] != null && car['image'] != ''
                    ? Image.network(
                        "http://10.122.38.180/carGOAdmin/my_car/${car['image']}",
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.directions_car, size: 40, color: Colors.blue),
                title: Text(car['car_name']),
                subtitle: Text("${car['brand']} ${car['model']} • ${car['status']}"),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') addOrEditCar(car: car);
                    if (value == 'delete') deleteCar(int.parse(car['id'].toString()));
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text("Edit")),
                    PopupMenuItem(value: 'delete', child: Text("Delete")),
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
