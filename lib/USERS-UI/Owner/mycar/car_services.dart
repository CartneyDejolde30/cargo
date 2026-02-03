import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import './api_constants.dart';

class CarService {
  /* ---------------- FETCH CARS ---------------- */
Future<List<Map<String, dynamic>>> fetchCars(int ownerId) async {
  try {
    final url = "${ApiConstants.carsApi}?owner_id=$ownerId";
    debugPrint("🚗 Fetching cars from: $url");
    debugPrint("🚗 Owner ID: $ownerId");
    
    // ✅ CRASH FIX: Timeout already present, add better error handling
    final response = await http
        .get(Uri.parse(url))
        .timeout(
          ApiConstants.apiTimeout,
          onTimeout: () {
            throw Exception('Connection timeout after ${ApiConstants.apiTimeout.inSeconds}s');
          },
        );

    debugPrint("🚗 Response status: ${response.statusCode}");
    debugPrint("🚗 Response body: ${response.body}");

    if (response.statusCode == 200) {
      // ✅ CRASH FIX: Wrap jsonDecode in try-catch
      try {
        final data = jsonDecode(response.body);

        debugPrint("🚗 Decoded data type: ${data.runtimeType}");
        debugPrint("🚗 Data length: ${data is List ? data.length : 'not a list'}");

        if (data is List) {
          return data.map<Map<String, dynamic>>((car) {
            const String baseUrl = ApiConstants.baseUrl;

            String imagePath = car['image']?.toString() ?? "";

            // Convert Windows/server path to web path
            if (imagePath.contains("uploads")) {
              imagePath = imagePath.split("uploads").last;
              imagePath = "uploads$imagePath";
            }

            return {
              ...Map<String, dynamic>.from(car),
              "image": "$baseUrl/$imagePath",
            };
          }).toList();
        }
      } catch (jsonError) {
        debugPrint("❌ JSON decode error: $jsonError");
        throw Exception('Invalid data format from server');
      }
    } else {
      debugPrint("❌ HTTP error: ${response.statusCode}");
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("❌ Error fetching cars: $e");
    // ✅ CRASH FIX: Rethrow with context for better error handling
    rethrow;
  }

  return [];
}


  /* ---------------- DELETE CAR ---------------- */
  Future<bool> deleteCar(int carId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.carsApi),
        body: {
          "action": "delete",
          "id": carId.toString(),
        },
      ).timeout(ApiConstants.apiTimeout);

      final result = jsonDecode(response.body);
      return result["success"] == true;
    } catch (e) {
      debugPrint("❌ Delete error: $e");
      return false;
    }
  }
}