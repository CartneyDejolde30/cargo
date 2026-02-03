// lib/USERS-UI/Owner/mycar/api_config.dart
import 'package:flutter_application_1/config/api_config.dart';

class ApiConfig {
  // ========================================
  // CENTRALIZED CONFIGURATION
  // All URLs now come from GlobalApiConfig
  // Change environment in lib/config/api_config.dart
  // ========================================
  
  // Base URLs (from GlobalApiConfig)
  static String get baseUrl => GlobalApiConfig.baseUrl;
  static String get apiUrl => GlobalApiConfig.apiUrl;
  static String get uploadsUrl => GlobalApiConfig.uploadsUrl;
  
  // API Endpoints - Dashboard & Bookings (from GlobalApiConfig)
  static String get dashboardStatsEndpoint => GlobalApiConfig.dashboardStatsEndpoint;
  static String get recentBookingsEndpoint => GlobalApiConfig.recentBookingsEndpoint;
  static String get upcomingBookingsEndpoint => GlobalApiConfig.upcomingBookingsEndpoint;
  static String get pendingRequestsEndpoint => GlobalApiConfig.pendingRequestsEndpoint;
  static String get activeBookingsEndpoint => GlobalApiConfig.activeBookingsEndpoint;
  static String get approveBookingEndpoint => GlobalApiConfig.approveRequestEndpoint;
  static String get rejectBookingEndpoint => GlobalApiConfig.rejectRequestEndpoint;
  static String get endTripEndpoint => GlobalApiConfig.endTripEndpoint;
  static String get transactionsEndpoint => GlobalApiConfig.transactionsEndpoint;
  static String get cancelledBookingsEndpoint => GlobalApiConfig.cancelledBookingsEndpoint;
  static String get rejectedBookingsEndpoint => GlobalApiConfig.rejectedBookingsEndpoint;
  
  // GPS Tracking Endpoints (from GlobalApiConfig)
  static String get updateLocationEndpoint => GlobalApiConfig.updateLocationEndpoint;
  static String get getCurrentLocationEndpoint => GlobalApiConfig.getCurrentLocationEndpoint;
  static String get getLocationHistoryEndpoint => GlobalApiConfig.getLocationHistoryEndpoint;
  static String getLocationHistoryDebugEndpoint = '${GlobalApiConfig.apiUrl}/GPS_tracking/get_location_history_debug.php';
  
  // Timeouts (from GlobalApiConfig)
  static Duration get apiTimeout => GlobalApiConfig.apiTimeout;
  static Duration get uploadTimeout => GlobalApiConfig.uploadTimeout;
  static Duration get gpsTimeout => GlobalApiConfig.gpsTimeout;
  
  // GPS Tracking Settings (from GlobalApiConfig)
  static double get minDistanceFilter => GlobalApiConfig.minDistanceFilter;
  static Duration get locationUpdateInterval => GlobalApiConfig.locationUpdateInterval;
  static int get maxLocationRetries => GlobalApiConfig.maxLocationRetries;
  static bool get enableBackgroundTracking => GlobalApiConfig.enableBackgroundTracking;
  
  // Helper Methods (delegated to GlobalApiConfig)
  static String getImageUrl(String? imagePath) => GlobalApiConfig.getImageUrl(imagePath);
  static String getCarImageUrl(String? imagePath) => GlobalApiConfig.getCarImageUrl(imagePath);
  static String getProfileImageUrl(String? imagePath) => GlobalApiConfig.getProfileImageUrl(imagePath);
  static bool isValidUrl(String url) => GlobalApiConfig.isValidUrl(url);
}