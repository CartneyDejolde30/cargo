import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cargo/config/api_config.dart';
import '../models/favorite.dart';

class FavoritesService {
  // Singleton pattern
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  // Cache favorites in memory
  List<Favorite> _cachedFavorites = [];
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    return userId != null ? int.tryParse(userId) : null;
  }

  /// Add a vehicle to favorites
  Future<Map<String, dynamic>> addFavorite(String vehicleType, int vehicleId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {
          'status': 'error',
          'message': 'User not logged in',
        };
      }

      final url = Uri.parse('${GlobalApiConfig.favoritesEndpoint}/add_favorite.php');
      final response = await http.post(url, body: {
        'user_id': userId.toString(),
        'vehicle_type': vehicleType,
        'vehicle_id': vehicleId.toString(),
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Invalidate cache on successful addition
        if (data['status'] == 'success') {
          _lastFetchTime = null;
        }
        
        return data;
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
      };
    }
  }

  /// Remove a vehicle from favorites
  Future<Map<String, dynamic>> removeFavorite(String vehicleType, int vehicleId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {
          'status': 'error',
          'message': 'User not logged in',
        };
      }

      final url = Uri.parse('${GlobalApiConfig.favoritesEndpoint}/remove_favorite.php');
      final response = await http.post(url, body: {
        'user_id': userId.toString(),
        'vehicle_type': vehicleType,
        'vehicle_id': vehicleId.toString(),
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Invalidate cache on successful removal
        if (data['status'] == 'success') {
          _lastFetchTime = null;
        }
        
        return data;
      } else {
        return {
          'status': 'error',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
      };
    }
  }

  /// Get all favorites for the current user
  Future<List<Favorite>> getFavorites({String? vehicleType, bool forceRefresh = false}) async {
    try {
      // Return cached data if valid and not forcing refresh
      if (!forceRefresh && 
          _lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
          _cachedFavorites.isNotEmpty) {
        return _cachedFavorites;
      }

      final userId = await _getUserId();
      if (userId == null) {
        return [];
      }

      var url = '${GlobalApiConfig.favoritesEndpoint}/get_favorites.php?user_id=$userId';
      if (vehicleType != null && vehicleType.isNotEmpty) {
        url += '&vehicle_type=$vehicleType';
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          final List<dynamic> favoritesJson = data['favorites'] ?? [];
          _cachedFavorites = favoritesJson.map((json) => Favorite.fromJson(json)).toList();
          _lastFetchTime = DateTime.now();
          return _cachedFavorites;
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  /// Check if a specific vehicle is favorited
  Future<bool> isFavorite(String vehicleType, int vehicleId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      final url = Uri.parse(
        '${GlobalApiConfig.favoritesEndpoint}/check_favorite.php?user_id=$userId&vehicle_type=$vehicleType&vehicle_id=$vehicleId'
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorite'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<Map<String, dynamic>> toggleFavorite(String vehicleType, int vehicleId) async {
    final isFav = await isFavorite(vehicleType, vehicleId);
    
    if (isFav) {
      return await removeFavorite(vehicleType, vehicleId);
    } else {
      return await addFavorite(vehicleType, vehicleId);
    }
  }

  /// Get favorites count
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }

  /// Clear cache (useful when logging out)
  void clearCache() {
    _cachedFavorites = [];
    _lastFetchTime = null;
  }
}