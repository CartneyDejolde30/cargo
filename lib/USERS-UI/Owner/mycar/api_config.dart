// lib/USERS-UI/Owner/mycar/api_config.dart
class ApiConfig {
  // ========================================
  // CHANGE THIS TO YOUR SERVER IP/DOMAIN
  // ========================================
  static const String _baseIP = '10.244.29.49'; // Change this to your server IP
  static const String _basePath = 'carGOAdmin';
  
  // Base URLs
  static const String baseUrl = 'http://$_baseIP/$_basePath/';
  static const String apiUrl = '${baseUrl}api/';
  static const String uploadsUrl = '${baseUrl}uploads/';
  
  // API Endpoints
  static const String dashboardStatsEndpoint = '${apiUrl}dashboard/dashboard_stats.php';
  static const String recentBookingsEndpoint = '${apiUrl}dashboard/recent_bookings.php';
  static const String upcomingBookingsEndpoint = '${apiUrl}dashboard/upcoming_bookings.php';
  static const String pendingRequestsEndpoint = '${apiUrl}get_owner_pending_requests.php';
  static const String activeBookingsEndpoint = '${apiUrl}get_owner_active_bookings.php';
  static const String approveBookingEndpoint = '${apiUrl}approve_booking.php';
  static const String rejectBookingEndpoint = '${apiUrl}reject_booking.php';
  static const String endTripEndpoint = '${apiUrl}bookings/end_trip.php';
  static const String transactionsEndpoint = '${apiUrl}get_owner_transactions.php';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 30);
  
  // Helper Methods
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    
    // Handle different image path formats
    if (imagePath.startsWith('uploads/')) {
      return '$baseUrl$imagePath';
    }
    return '$uploadsUrl$imagePath';
  }
  
  static String getCarImageUrl(String? imagePath) => getImageUrl(imagePath);
  static String getProfileImageUrl(String? imagePath) => getImageUrl(imagePath);
  
  // Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}