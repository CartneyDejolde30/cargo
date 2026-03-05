import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service to handle persistent authentication
/// Keeps users logged in after closing the app
class PersistentAuthService {
  static final PersistentAuthService _instance = PersistentAuthService._internal();
  factory PersistentAuthService() => _instance;
  PersistentAuthService._internal();

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final email = prefs.getString('email');
      
      // User is logged in if both user_id and email exist
      final isLoggedIn = userId != null && email != null && userId.isNotEmpty && email.isNotEmpty;
      
      debugPrint('🔐 Checking login status: ${isLoggedIn ? "LOGGED IN" : "NOT LOGGED IN"}');
      if (isLoggedIn) {
        debugPrint('   └─ User ID: $userId');
        debugPrint('   └─ Email: $email');
      }
      
      return isLoggedIn;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return false;
    }
  }

  /// Get user role (Owner or Renter)
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      debugPrint('👤 User role: $role');
      return role;
    } catch (e) {
      debugPrint('❌ Error getting user role: $e');
      return null;
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  /// Get user data
  Future<Map<String, String?>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'user_id': prefs.getString('user_id'),
        'fullname': prefs.getString('fullname'),
        'email': prefs.getString('email'),
        'role': prefs.getString('role'),
        'phone': prefs.getString('phone'),
        'address': prefs.getString('address'),
        'municipality': prefs.getString('municipality'),
        'profile_image': prefs.getString('profile_image'),
        'is_verified': prefs.getString('is_verified'),
      };
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return {};
    }
  }

  /// Save user session data (called after successful login)
  Future<void> saveUserSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('user_id', userData['id'].toString());
      await prefs.setString('fullname', userData['fullname'] ?? '');
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('role', userData['role'] ?? '');
      await prefs.setString('phone', userData['phone'] ?? '');
      await prefs.setString('address', userData['address'] ?? '');
      await prefs.setString('municipality', userData['municipality'] ?? '');
      await prefs.setString('profile_image', userData['profile_image'] ?? '');
      await prefs.setString('is_verified', (userData['is_verified'] ?? 0).toString());
      
      if (userData['token'] != null) {
        await prefs.setString('auth_token', userData['token']);
      }
      
      // Mark that user wants to stay logged in
      await prefs.setBool('stay_logged_in', true);
      
      debugPrint('✅ User session saved');
    } catch (e) {
      debugPrint('❌ Error saving user session: $e');
    }
  }

  /// Clear user session (logout)
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all user-related data
      await prefs.remove('user_id');
      await prefs.remove('fullname');
      await prefs.remove('email');
      await prefs.remove('role');
      await prefs.remove('phone');
      await prefs.remove('address');
      await prefs.remove('municipality');
      await prefs.remove('profile_image');
      await prefs.remove('is_verified');
      await prefs.remove('auth_token');
      await prefs.remove('stay_logged_in');
      
      debugPrint('✅ User session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user session: $e');
    }
  }

  /// Check if user wants to stay logged in
  Future<bool> shouldStayLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('stay_logged_in') ?? false;
    } catch (e) {
      debugPrint('❌ Error checking stay logged in preference: $e');
      return false;
    }
  }
}
