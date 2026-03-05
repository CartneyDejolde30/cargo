// Insurance Service for API communication

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cargo/config/api_config.dart';
import '../models/insurance_models.dart';

class InsuranceService {
  static String get baseUrl => GlobalApiConfig.insuranceBaseUrl;

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

  /// File an insurance claim with photo uploads
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
      // Step 1: File the claim first (without photos)
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
          'evidence_photos': [], // Will be updated after upload
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to file claim');
      }

      final claimId = data['data']['claim_id'];

      // Step 2: Upload photos if any
      if (evidencePhotos != null && evidencePhotos.isNotEmpty) {
        await uploadClaimPhotos(claimId, evidencePhotos);
      }

      return data['data'];
    } catch (e) {
      throw Exception('Error filing claim: $e');
    }
  }

  /// Upload claim evidence photos
  static Future<List<String>> uploadClaimPhotos(
    int claimId,
    List<String> photoFilePaths,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_claim_photos.php'),
      );

      // Add claim_id
      request.fields['claim_id'] = claimId.toString();

      // Add photos
      for (int i = 0; i < photoFilePaths.length; i++) {
        var file = await http.MultipartFile.fromPath(
          'photos',
          photoFilePaths[i],
        );
        request.files.add(file);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<String> photoUrls = List<String>.from(data['data']['photo_urls']);
          
          // Update claim with photo URLs
          await updateClaimPhotos(claimId, photoUrls);
          
          return photoUrls;
        } else {
          throw Exception(data['message'] ?? 'Failed to upload photos');
        }
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading photos: $e');
    }
  }

  /// Update claim with uploaded photo URLs
  static Future<void> updateClaimPhotos(int claimId, List<String> photoUrls) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_claim_photos.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'claim_id': claimId,
          'photo_urls': photoUrls,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to update claim photos');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating claim photos: $e');
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

  /// Get all insurance policies for a vehicle owner
  static Future<List<InsurancePolicy>> getOwnerPolicies({
    required int ownerId,
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'owner_id': ownerId.toString(),
        'status': status,
        if (search.isNotEmpty) 'search': search,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/admin/get_owner_policies.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<InsurancePolicy> policies = [];
          for (var item in data['data']) {
            policies.add(InsurancePolicy.fromJson(item));
          }
          return policies;
        } else {
          throw Exception(data['message'] ?? 'Failed to load owner policies');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching owner policies: $e');
    }
  }

  /// Format currency
  static String formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}
