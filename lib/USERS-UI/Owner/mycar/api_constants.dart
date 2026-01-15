class ApiConstants {
  // Base URL
  static const String baseUrl = "http://10.244.29.49/carGOAdmin/";
  
  // API Endpoints
  static const String carsApi = "${baseUrl}cars_api.php";
  static const String checkVerificationApi = "${baseUrl}api/check_verification.php";
  
  // Helper methods
  static String getCarImageUrl(String imagePath) => "$baseUrl$imagePath";
  
  // Timeout duration
  static const Duration apiTimeout = Duration(seconds: 10);
}