import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/USERS-UI/Owner/models/user_verification.dart';

class VerificationService {

  // Change to your real endpoint
  static const String baseUrl = "http://10.72.15.180/carGOAdmin/submit_verification.php";

  /// Submit full verification form (multi-step final submit)
  static Future<bool> submitVerification(UserVerification data) async {
    var uri = Uri.parse("${baseUrl}submit_verification.php");

    var request = http.MultipartRequest("POST", uri);

    // Convert simple fields
    data.toJson().forEach((key, value) {
      if (value != null && value is! DateTime) {
        request.fields[key] = value.toString();
      }
    });

    // Attach files
    if (data.idFrontPhoto != null)
      request.files.add(await http.MultipartFile.fromPath(
        "id_front_photo", data.idFrontPhoto!,
      ));

    if (data.idBackPhoto != null)
      request.files.add(await http.MultipartFile.fromPath(
        "id_back_photo", data.idBackPhoto!,
      ));

    if (data.selfiePhoto != null)
      request.files.add(await http.MultipartFile.fromPath(
        "selfie_photo", data.selfiePhoto!,
      ));

    final response = await request.send();

    return response.statusCode == 200;
  }

  /// Get verification status for logged-in user
  static Future<String?> getVerificationStatus(int userId) async {
    final res = await http.post(
      Uri.parse("${baseUrl}get_verification_status.php"),
      body: {"user_id": userId.toString()},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["status"];
    }
    return null;
  }
}
