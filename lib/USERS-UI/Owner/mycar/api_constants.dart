class ApiConstants {
  // ========================================
  // ⚠️ CHANGE THIS TO YOUR COMPUTER'S IP!
  // Run 'ipconfig' in Command Prompt to find it
  // Example: 192.168.1.100
  // ========================================
  static const String baseUrl = "http://10.139.150.2/carGOAdmin/"; // ← PUT YOUR IP HERE!
  
  // API Endpoints
  static const String carsApi = "${baseUrl}cars_api.php";
  static const String checkVerificationApi = "${baseUrl}api/check_verification.php";
  
  // Helper methods
  static String getCarImageUrl(String imagePath) {
  return "$baseUrl$imagePath";
}

  
  // Timeout duration
  static const Duration apiTimeout = Duration(seconds: 10);
}