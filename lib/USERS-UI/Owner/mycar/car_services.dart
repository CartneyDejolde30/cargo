import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import './api_constants.dart';

class CarService {
  /* ---------------- FETCH CARS ---------------- */
  Future<List<Map<String, dynamic>>> fetchCars(int ownerId) async {
    try {
      final response = await http
          .get(Uri.parse("${ApiConstants.carsApi}?owner_id=$ownerId"))
          .timeout(ApiConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching cars: $e");
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