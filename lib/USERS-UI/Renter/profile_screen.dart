import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/bottom_nav_bar.dart';
import 'package:flutter_application_1/USERS-UI/change_password.dart';
import 'package:flutter_application_1/USERS-UI/Renter/edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "User";
  String userEmail = "";
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
      userName = prefs.getString("fullname") ?? "User";
      userEmail = prefs.getString("email") ?? "No Email";
      phone = prefs.getString("phone") ?? "";
      address = prefs.getString("address") ?? "";
      profileImage = prefs.getString("profile_image") ?? "";
    });
  }

  ImageProvider? _getProfileImage() {
    if (profileImage.isNotEmpty) {
      return NetworkImage(profileImage);
    }
    return null;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text("Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset("assets/cargo.png", width: 32),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [

            // ---------------- Profile Picture (NOT EDITABLE DIRECTLY)
            CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _getProfileImage(),
              child: _getProfileImage() == null
                  ? const Icon(Icons.person, size: 65, color: Colors.white70)
                  : null,
            ),

            const SizedBox(height: 15),
            Text(userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(userEmail, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),

            const SizedBox(height: 30),

            _menu(Icons.person_outline, "Edit Profile", () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfile()),
              );
              loadUserData();
            }),

            _menu(Icons.lock_outline, "Change Password", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
            }),

            _menu(Icons.support_agent_outlined, "Help & Support", () {}),
            _menu(Icons.info_outline, "About App", () {}),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Logout", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
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
              Expanded(
                child: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
