import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "http://10.72.15.180/carGOAdmin/change_password.php";

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();
  bool loading = false;

  Future<void> changePassword() async {
    if (newPassController.text != confirmPassController.text) {
      _showMessage("New passwords do not match.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString("user_id") ?? "";

    if (userId.isEmpty) {
      _showMessage("User not logged in.");
      return;
    }

    setState(() => loading = true);

    final response = await http.post(
      Uri.parse("$baseUrl/change_password.php"),
      body: {
        "user_id": userId,
        "old_password": oldPassController.text.trim(),
        "new_password": newPassController.text.trim(),
      },
    );

    setState(() => loading = false);

    final data = jsonDecode(response.body);

    _showMessage(data["message"]);

    if (data["success"] == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Change Password", style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input("Current Password", oldPassController, true),
            const SizedBox(height: 12),
            _input("New Password", newPassController, true),
            const SizedBox(height: 12),
            _input("Confirm New Password", confirmPassController, true),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text("Update Password", style: GoogleFonts.poppins(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
