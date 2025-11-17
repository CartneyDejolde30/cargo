import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String fullname = "";
  String email = "";
  String role = "";
  String phone = "";
  String address = "";
  String profileImage = "";
  File? imageFile;
  Uint8List? webImage;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullname = prefs.getString("fullname") ?? "Unknown";
      email = prefs.getString("email") ?? "No email";
      role = prefs.getString("role") ?? "No role";
      phone = prefs.getString("phone") ?? "No phone";
      address = prefs.getString("address") ?? "No address";
      profileImage = prefs.getString("profile_image") ?? "";

      nameController.text = fullname;
      phoneController.text = phone;
      addressController.text = address;
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  Future<void> pickImage({VoidCallback? onUpdate}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        webImage = await picked.readAsBytes();
      } else {
        imageFile = File(picked.path);
      }
      if (onUpdate != null) onUpdate();
      setState(() {}); // update main page
    }
  }

  ImageProvider? _getProfileImage() {
    if (imageFile != null) return FileImage(imageFile!);
    if (webImage != null) return MemoryImage(webImage!);
    if (profileImage.isNotEmpty) {
      // Ensure only filename is used in case database stores full path
      final filename = profileImage.split('/').last;
      return NetworkImage("http://172.31.51.180/carGOAdmin/uploads/$filename");
    }
    return null;
  }

  Future<void> updateProfile() async {
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => pickImage(onUpdate: () {
                    setStateDialog(() {});
                  }),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  int userId = prefs.getInt("user_id") ?? 0;

                  var request = http.MultipartRequest(
                    'POST',
                    Uri.parse("http://172.31.51.180/carGOAdmin/update.php"),
                  );

                  request.fields['user_id'] = userId.toString();
                  request.fields['fullname'] = nameController.text;
                  request.fields['phone'] = phoneController.text;
                  request.fields['address'] = addressController.text;

                  if (!kIsWeb && imageFile != null) {
                    request.files.add(await http.MultipartFile.fromPath(
                      'profile_image',
                      imageFile!.path,
                    ));
                  }

                  if (kIsWeb && webImage != null) {
                    request.files.add(http.MultipartFile.fromBytes(
                      'profile_image',
                      webImage!,
                      filename: 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.png',
                    ));
                  }

                  var response = await request.send();
                  var respStr = await response.stream.bytesToString();
                  var jsonResp = jsonDecode(respStr);

                  if (response.statusCode == 200 && jsonResp['status'] == 'success') {
                    await prefs.setString("fullname", jsonResp['fullname']);
                    await prefs.setString("phone", jsonResp['phone']);
                    await prefs.setString("address", jsonResp['address'] ?? "");
                    if (jsonResp['profile_image'] != null && jsonResp['profile_image'] != "") {
                      await prefs.setString("profile_image", jsonResp['profile_image']);
                    }

                    setState(() {
                      fullname = jsonResp['fullname'];
                      phone = jsonResp['phone'];
                      address = jsonResp['address'] ?? "";
                      if (jsonResp['profile_image'] != null && jsonResp['profile_image'] != "") {
                        profileImage = jsonResp['profile_image'];
                      }
                      // Clear temp images after successful upload
                      imageFile = null;
                      webImage = null;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile updated successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(jsonResp['message'] ?? "Update failed")),
                    );
                  }
                } catch (e) {
                  print("Error updating profile: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error connecting to server")),
                  );
                } finally {
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "CarGo",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Image.asset(
                    "assets/cargo.png",
                    width: 45,
                    height: 45,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImage() == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        title: Text(fullname,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        subtitle: Text(role, style: TextStyle(color: Colors.grey.shade700)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: updateProfile,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.email, color: Colors.blue),
                            title: const Text("Email"),
                            subtitle: Text(email),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.phone, color: Colors.blue),
                            title: const Text("Phone"),
                            subtitle: Text(phone),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.email, color: Colors.blue),
                            title: const Text("Address"),
                            subtitle: Text(address),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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
