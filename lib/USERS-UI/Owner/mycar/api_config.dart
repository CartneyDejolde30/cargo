// lib/USERS-UI/Owner/mycar/api_config.dart
class ApiConfig {
  // ========================================
  // ⚠️ CHANGE THIS TO YOUR COMPUTER'S IP!
  // Run 'ipconfig' in Command Prompt to find it
  // Example: 192.168.1.100
  // ========================================
  static const String _baseIP = '10.139.150.2'; // ← PUT YOUR IP HERE!
  static const String _basePath = 'carGOAdmin';
  
  // Base URLs
  static const String baseUrl = 'http://$_baseIP/$_basePath/';
  static const String apiUrl = '${baseUrl}api/';
  static const String uploadsUrl = '${baseUrl}uploads/';
  
  // API Endpoints
  static const String dashboardStatsEndpoint = '${apiUrl}dashboard/dashboard_stats.php';
  static const String recentBookingsEndpoint = '${apiUrl}dashboard/recent_bookings.php';
  static const String upcomingBookingsEndpoint = '${apiUrl}dashboard/upcoming_bookings.php';
  static const String pendingRequestsEndpoint = '${apiUrl}bookings/get_owner_pending_requests.php'; // FIXED: Added bookings/ subdirectory
  static const String activeBookingsEndpoint = '${apiUrl}bookings/get_owner_active_bookings.php'; // FIXED: Added bookings/ subdirectory
  static const String approveBookingEndpoint = '${apiUrl}approve_request.php';
  static const String rejectBookingEndpoint = '${apiUrl}reject_booking.php';
  static const String endTripEndpoint = '${apiUrl}bookings/end_trip.php';
  static const String transactionsEndpoint = '${apiUrl}get_owner_transactions.php';

   static String get cancelledBookingsEndpoint => "${baseUrl}api/bookings/cancelled_bookings.php";
  static String get rejectedBookingsEndpoint => "${baseUrl}api/bookings/rejected_bookings.php";
  
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