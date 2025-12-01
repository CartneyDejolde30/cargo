import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile>
    with SingleTickerProviderStateMixin {

  final String apiUrl = "http://10.72.15.180/carGOAdmin/update.php";

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  File? imageFile;
  Uint8List? webImage;
  String storedImage = "";

  bool saving = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    load();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    nameController.text = prefs.getString("fullname") ?? "";
    phoneController.text = prefs.getString("phone") ?? "";
    addressController.text = prefs.getString("address") ?? "";
    storedImage = prefs.getString("profile_image") ?? "";
    setState(() {});
  }

  Future pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    if (kIsWeb) {
      webImage = await file.readAsBytes();
    } else {
      imageFile = File(file.path);
    }

    setState(() {});
  }

  ImageProvider? getImage() {
    if (imageFile != null) return FileImage(imageFile!);
    if (webImage != null) return MemoryImage(webImage!);
    if (storedImage.isNotEmpty) return NetworkImage(storedImage);
    return null;
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    setState(() => saving = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? "";

    var req = http.MultipartRequest("POST", Uri.parse(apiUrl));
    req.fields["user_id"] = userId;
    req.fields["fullname"] = nameController.text.trim();
    req.fields["phone"] = phoneController.text.trim();
    req.fields["address"] = addressController.text.trim();

    if (imageFile != null) {
      req.files.add(await http.MultipartFile.fromPath("profile_image", imageFile!.path));
    } else if (kIsWeb && webImage != null) {
      req.files.add(http.MultipartFile.fromBytes(
        "profile_image",
        webImage!,
        filename: "profile_${DateTime.now().millisecondsSinceEpoch}.png",
      ));
    }

    final response = await req.send();
    final json = jsonDecode(await response.stream.bytesToString());

    if (json["success"] == true) {
      final updated = json["user"];

      await prefs.setString("fullname", updated["fullname"]);
      await prefs.setString("phone", updated["phone"] ?? "");
      await prefs.setString("address", updated["address"] ?? "");
      await prefs.setString("profile_image", updated["profile_image"]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // <- trigger refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(json["message"] ?? "Update failed")),
      );
    }

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        foregroundColor: Colors.black,
      ),

      body: FadeTransition(
        opacity: _fadeController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 15),

              // Profile Avatar with fade animation
              AnimatedScale(
                duration: const Duration(milliseconds: 350),
                scale: 1.05,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundImage: getImage(),
                      backgroundColor: Colors.grey.shade300,
                      child: getImage() == null
                          ? const Icon(Icons.person, size: 65, color: Colors.black45)
                          : null,
                    ),
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.black,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              _styledInput("Full Name", nameController),
              _styledInput("Phone Number", phoneController, type: TextInputType.phone),
              _styledInput("Address", addressController),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Sticky save button
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: saving ? null : save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _styledInput(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
