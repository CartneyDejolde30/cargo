import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/USERS-UI/Owner/models/user_verification.dart';

class VerificationService {
  // IP Configuration
  static const String _localIP = "192.168.1.11"; // Your computer's IP for mobile
  
  // Automatically chooses correct URL based on platform
  static const String baseUrl = kIsWeb 
      ? "http://localhost/carGOAdmin"           // For web debugging
      : "http://$_localIP/carGOAdmin";          // For mobile app

  static Future<Map<String, dynamic>> submitVerification(UserVerification data) async {
    try {
      var uri = Uri.parse("$baseUrl/submit_verification.php");
      var request = http.MultipartRequest("POST", uri);

      print("🔗 Platform: ${kIsWeb ? 'WEB' : 'MOBILE'}");
      print("🔗 Connecting to: $uri");

      // Add form fields
      request.fields['user_id'] = data.userId.toString();
      request.fields['first_name'] = data.firstName ?? '';
      request.fields['last_name'] = data.lastName ?? '';
      request.fields['email'] = data.email ?? '';
      request.fields['mobile'] = data.mobileNumber ?? '';
      request.fields['gender'] = data.gender ?? '';
      request.fields['dob'] = data.dateOfBirth?.toIso8601String().substring(0, 10) ?? '';
      request.fields['region'] = data.permRegion ?? 'Region XIII (Caraga)';
      request.fields['province'] = data.permProvince ?? 'Agusan del Sur';
      request.fields['municipality'] = data.permCity ?? '';
      request.fields['barangay'] = data.permBarangay ?? '';
      request.fields['id_type'] = data.idType ?? '';

      print("📋 User: ${data.firstName} ${data.lastName}");

      // Handle file uploads
      if (kIsWeb) {
        // Web: Show warning but continue (for testing UI/flow)
        print("⚠️ Running on WEB - File upload functionality limited");
        print("⚠️ For full testing, please use mobile device/emulator");
        
        // You could still send dummy data or skip file validation on web
        return {
          "success": false,
          "message": "Web upload not supported. Please test on mobile device."
        };
      } else {
        // Mobile: Add actual files
        if (data.idFrontPhoto == null || data.idBackPhoto == null || data.selfiePhoto == null) {
          print("❌ Missing required photos");
          return {
            "success": false,
            "message": "All photos are required"
          };
        }

        request.files.add(await http.MultipartFile.fromPath(
          'id_front_photo',
          data.idFrontPhoto!,
        ));
        request.files.add(await http.MultipartFile.fromPath(
          'id_back_photo',
          data.idBackPhoto!,
        ));
        request.files.add(await http.MultipartFile.fromPath(
          'selfie_photo',
          data.selfiePhoto!,
        ));
        
        print("✅ All photos attached");
      }

      print("📤 Sending request...");
      
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );
      
      final responseBody = await response.stream.bytesToString();
      
      print("📥 Status: ${response.statusCode}");
      print("📥 Response: $responseBody");

      if (response.statusCode == 200) {
        try {
          return json.decode(responseBody) as Map<String, dynamic>;
        } catch (e) {
          print("❌ JSON Parse Error: $e");
          return {
            "success": false,
            "message": "Invalid server response"
          };
        }
      } else {
        return {
          "success": false,
          "message": "Server error (${response.statusCode})"
        };
      }
    } catch (e, stackTrace) {
      print("❌ Exception: $e");
      print("❌ Stack: $stackTrace");
      return {
        "success": false,
        "message": "Connection failed: ${e.toString()}"
      };
    }
  }

  static Future<Map<String, dynamic>?> getVerificationStatus(int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/get_verification_status.php"),
        body: {"user_id": userId.toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("❌ Error getting status: $e");
    }
    return null;
  }
}