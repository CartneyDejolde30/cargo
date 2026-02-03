// Insurance Service for API communication

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/insurance_models.dart';

class InsuranceService {
  static const String baseUrl = 'http://10.218.197.49/carGOAdmin/api/insurance';

  /// Get available insurance coverage types
  static Future<List<InsuranceCoverage>> getCoverageTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_coverage_types.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<InsuranceCoverage> coverages = [];
          for (var item in data['data']) {
            coverages.add(InsuranceCoverage.fromJson(item));
          }
          return coverages;
        } else {
          throw Exception(data['message'] ?? 'Failed to load coverage types');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching coverage types: $e');
    }
  }

  /// Create insurance policy for a booking
  static Future<Map<String, dynamic>> createPolicy({
    required int bookingId,
    required int userId,
    required String coverageType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_policy.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': bookingId,
          'user_id': userId,
          'coverage_type': coverageType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to create policy');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating policy: $e');
    }
  }

  /// Get insurance policy details
  static Future<InsurancePolicy> getPolicy({
    required int userId,
    int? bookingId,
    int? policyId,
  }) async {
    try {
      final queryParams = {
        'user_id': userId.toString(),
        if (bookingId != null) 'booking_id': bookingId.toString(),
        if (policyId != null) 'policy_id': policyId.toString(),
      };

      final uri = Uri.parse('$baseUrl/get_policy.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return InsurancePolicy.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load policy');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching policy: $e');
    }
  }

  /// File an insurance claim
  static Future<Map<String, dynamic>> fileClaim({
    required int policyId,
    required int bookingId,
    required int userId,
    required String claimType,
    required DateTime incidentDate,
    required String incidentDescription,
    required double claimedAmount,
    String? incidentLocation,
    String? policeReportNumber,
    List<String>? evidencePhotos,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/file_claim.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'policy_id': policyId,
          'booking_id': bookingId,
          'user_id': userId,
          'claim_type': claimType,
          'incident_date': incidentDate.toIso8601String(),
          'incident_description': incidentDescription,
          'claimed_amount': claimedAmount,
          'incident_location': incidentLocation,
          'police_report_number': policeReportNumber,
          'evidence_photos': evidencePhotos ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to file claim');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error filing claim: $e');
    }
  }

  /// Get insurance claims for a user
  static Future<List<InsuranceClaim>> getClaims({
    required int userId,
    String status = 'all',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/get_claims.php').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'status': status,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<InsuranceClaim> claims = [];
          for (var item in data['data']) {
            claims.add(InsuranceClaim.fromJson(item));
          }
          return claims;
        } else {
          throw Exception(data['message'] ?? 'Failed to load claims');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching claims: $e');
    }
  }

  /// Get specific claim details
  static Future<InsuranceClaim> getClaimDetails({
    required int userId,
    required int claimId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/get_claims.php').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'claim_id': claimId.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return InsuranceClaim.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load claim');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching claim: $e');
    }
  }

  /// Calculate insurance premium
  static double calculatePremium({
    required double rentalAmount,
    required double premiumRate,
  }) {
    return rentalAmount * (premiumRate / 100);
  }

  /// Format currency
  static String formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}
