// ========================================
// GLOBAL API CONFIGURATION
// ========================================
// This file centralizes all API endpoint configurations
// Change the domain here to switch between development and production

class GlobalApiConfig {
  // ========================================
  // ENVIRONMENT CONFIGURATION
  // ========================================
  
  // Set to true for development (local), false for production (Hostinger)
  static const bool isDevelopment = false; // Changed to production - using Hostinger
  
  // Development Configuration (Local)
  static const String _devBaseIP = '10.218.197.49';
  static const String _devBasePath = 'carGOAdmin';
  static const String _devBaseUrl = 'http://$_devBaseIP/$_devBasePath';
  
  // Production Configuration (Hostinger)
  static const String _prodDomain = 'cargoph.online';
  static const String _prodBasePath = 'carGOAdmin';
  static const String _prodBaseUrl = 'https://$_prodDomain/$_prodBasePath';
  
  
  // ========================================
  // ACTIVE CONFIGURATION (Auto-selected)
  // ========================================
  static String get baseUrl => isDevelopment ? _devBaseUrl : _prodBaseUrl;
  static String get apiUrl => '$baseUrl/api';
  static String get uploadsUrl => '$baseUrl/uploads';
  
  // ========================================
  // COMMON API ENDPOINTS
  // ========================================
  
  // Authentication
  static String get loginEndpoint => '$baseUrl/login.php';
  static String get registerEndpoint => '$baseUrl/register.php';
  static String get logoutEndpoint => '$baseUrl/logout.php';
  static String get changePasswordEndpoint => '$baseUrl/backend_setting/update_password.php';
  
  // User Profile
  static String get updateProfileEndpoint => '$baseUrl/update.php';
  static String get getProfileEndpoint => '$baseUrl/get_profile.php';
  
  // Verification
  static String get checkVerificationEndpoint => '$apiUrl/check_verification.php';
  static String get submitVerificationEndpoint => '$apiUrl/submit_verification.php';
  
  // Cars & Vehicles
  static String get carsApiEndpoint => '$baseUrl/cars_api.php';
  static String get getCarsEndpoint => '$apiUrl/get_cars.php';
  static String get getCarsFilteredEndpoint => '$apiUrl/get_cars_filtered.php';
  static String get getCarDetailsEndpoint => '$apiUrl/get_car_details.php';
  static String get getFilterOptionsEndpoint => '$apiUrl/get_filter_options.php';
  
  // Motorcycles
  static String get getMotorcyclesFilteredEndpoint => '$apiUrl/get_motorcycles_filtered.php';
  static String get getMotorcycleFilterOptionsEndpoint => '$apiUrl/get_motorcycle_filter_options.php';
  
  // Bookings
  static String get createBookingEndpoint => '$apiUrl/create_booking.php';
  static String get getMyBookingsEndpoint => '$apiUrl/get_my_bookings.php';
  static String get cancelBookingEndpoint => '$apiUrl/cancel_booking.php';
  static String get approveRequestEndpoint => '$apiUrl/approve_request.php';
  static String get rejectRequestEndpoint => '$apiUrl/reject_request.php';
  
  // Dashboard & Owner
  static String get dashboardStatsEndpoint => '$apiUrl/dashboard/dashboard_stats.php';
  static String get recentBookingsEndpoint => '$apiUrl/dashboard/recent_bookings.php';
  static String get upcomingBookingsEndpoint => '$apiUrl/dashboard/upcoming_bookings.php';
  static String get pendingRequestsEndpoint => '$apiUrl/bookings/get_owner_pending_requests.php';
  static String get activeBookingsEndpoint => '$apiUrl/bookings/get_owner_active_bookings.php';
  static String get cancelledBookingsEndpoint => '$apiUrl/bookings/cancelled_bookings.php';
  static String get rejectedBookingsEndpoint => '$apiUrl/bookings/rejected_bookings.php';
  static String get endTripEndpoint => '$apiUrl/bookings/end_trip.php';
  static String get transactionsEndpoint => '$apiUrl/get_owner_transactions.php';
  
  // GPS Tracking
  static String get updateLocationEndpoint => '$apiUrl/GPS_tracking/update_location.php';
  static String get getCurrentLocationEndpoint => '$apiUrl/GPS_tracking/get_current_location.php';
  static String get getLocationHistoryEndpoint => '$apiUrl/GPS_tracking/get_location_history.php';
  
  // Mileage & Odometer
  static String get recordStartOdometerEndpoint => '$apiUrl/mileage/record_start_odometer.php';
  static String get recordEndOdometerEndpoint => '$apiUrl/mileage/record_end_odometer.php';
  static String get updateGpsDistanceEndpoint => '$apiUrl/mileage/update_gps_distance.php';
  
  // Insurance
  static String get insuranceBaseUrl => '$apiUrl/insurance';
  static String get createPolicyEndpoint => '$insuranceBaseUrl/create_policy.php';
  static String get getPolicyEndpoint => '$insuranceBaseUrl/get_policy.php';
  static String get fileClaimEndpoint => '$insuranceBaseUrl/file_claim.php';
  
  // Payments
  static String get submitLateFeePaymentEndpoint => '$apiUrl/payment/submit_late_fee_payment.php';
  static String get verifyPaymentEndpoint => '$apiUrl/payment/verify_payment.php';
  
  // Payout
  static String get payoutDashboardEndpoint => '$apiUrl/payout/get_owner_payouts.php';
  static String get payoutHistoryEndpoint => '$apiUrl/payout/get_owner_payout_history.php';
  static String get payoutSettingsEndpoint => '$apiUrl/payout/get_payout_settings.php';
  static String get updatePayoutSettingsEndpoint => '$apiUrl/payout/update_payout_settings.php';
  
  // Refunds
  static String get refundHistoryEndpoint => '$apiUrl/refund/get_refund_history.php';
  static String get requestRefundEndpoint => '$apiUrl/refund/request_refund.php';
  
  // Reports & Reviews
  static String get submitReportEndpoint => '$apiUrl/submit_report.php';
  static String get submitReviewEndpoint => '$apiUrl/submit_review.php';
  static String get getReviewsEndpoint => '$apiUrl/get_reviews.php';
  
  // Receipts
  static String get generateReceiptEndpoint => '$apiUrl/receipts/generate_receipt.php';
  static String get getReceiptHistoryEndpoint => '$apiUrl/receipts/get_receipt_history.php';
  
  // Notifications
  static String get saveFcmTokenEndpoint => '$apiUrl/save_fcm_token.php';
  static String get getNotificationsEndpoint => '$baseUrl/get_notification.php';
  
  // Availability Calendar
  static String get getBlockedDatesEndpoint => '$apiUrl/availability/get_blocked_dates.php';
  static String get blockDatesEndpoint => '$apiUrl/availability/block_dates.php';
  static String get unblockDatesEndpoint => '$apiUrl/availability/unblock_dates.php';
  
  // Overdue Management
  static String get overdueBaseUrl => '$apiUrl/overdue';
  
  // Host Information
  static String get getOwnerProfileEndpoint => '$apiUrl/get_owner_profile.php';
  static String get getOwnerCarsEndpoint => '$apiUrl/get_owner_cars.php';
  static String get getOwnerReviewsEndpoint => '$apiUrl/get_owner_reviews.php';
  
  // Google Sign-In
  static String get googleRegisterEndpoint => '$baseUrl/google_register.php';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Get full image URL from relative path
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/300';
    }
    
    // Already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // Remove leading slash or "uploads/" prefix
    String cleanPath = imagePath;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    if (cleanPath.startsWith('uploads/')) {
      cleanPath = cleanPath.substring(8);
    }
    
    return '$uploadsUrl/$cleanPath';
  }
  
  /// Get car image URL
  static String getCarImageUrl(String? imagePath) => getImageUrl(imagePath);
  
  /// Get profile image URL
  static String getProfileImageUrl(String? imagePath) => getImageUrl(imagePath);
  
  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  // ========================================
  // TIMEOUT CONFIGURATIONS
  // ========================================
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 30);
  static const Duration gpsTimeout = Duration(seconds: 10);
  
  // ========================================
  // GPS TRACKING SETTINGS
  // ========================================
  static const double minDistanceFilter = 10.0; // meters
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const int maxLocationRetries = 3;
  static const bool enableBackgroundTracking = true;
  
  // ========================================
  // DEBUG INFO
  // ========================================
  static void printConfig() {
    print('========================================');
    print('API CONFIGURATION');
    print('========================================');
    print('Environment: ${isDevelopment ? "DEVELOPMENT" : "PRODUCTION"}');
    print('Base URL: $baseUrl');
    print('API URL: $apiUrl');
    print('Uploads URL: $uploadsUrl');
    print('========================================');
  }
}
