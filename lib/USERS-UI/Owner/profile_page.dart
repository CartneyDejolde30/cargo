import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/USERS-UI/change_password.dart';
import 'package:flutter_application_1/USERS-UI/Owner/edit_profile_screen.dart';




class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String apiUrl = "http://10.72.15.180/carGOAdmin/update.php";

  String fullname = "";
  String email = "";
  String phone = "";
  String address = "";
  String profileImage = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullname = prefs.getString("fullname") ?? "Unknown";
      email = prefs.getString("email") ?? "Not Available";
      phone = prefs.getString("phone") ?? "";
      address = prefs.getString("address") ?? "";
      profileImage = prefs.getString("profile_image") ?? "";
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  ImageProvider? getProfileImage() {
    if (profileImage.isNotEmpty) return NetworkImage(profileImage);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Image.asset("assets/cargo.png", width: 35),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [

            // ---- Profile Image (NO EDIT ACTION HERE) ----
            CircleAvatar(
              radius: 65,
              backgroundImage: getProfileImage(),
              backgroundColor: Colors.grey.shade300,
              child: getProfileImage() == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 14),
            Text(fullname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            _menu(Icons.person_outline, "Edit Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(api: apiUrl)),
              ).then((_) => loadUserData());
            }),

            _menu(Icons.lock_outline, "Change Password", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
            }),

            _menu(Icons.help_outline, "Help & Support", () {}),
            _menu(Icons.info_outline, "About App", () {}),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(IconData icon, String title, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: action,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.black87),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
