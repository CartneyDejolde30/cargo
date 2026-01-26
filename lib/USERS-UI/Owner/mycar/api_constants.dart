class ApiConstants {
  // ========================================
  // ⚠️ CHANGE THIS TO YOUR COMPUTER'S IP!
  // Run 'ipconfig' in Command Prompt to find it
  // Example: 192.168.1.100
  // ========================================
  static const String baseUrl = "http://10.244.29.49/carGOAdmin/";

  // APIs
  static const String carsApi = "${baseUrl}cars_api.php";
  static const String checkVerificationApi =
      "${baseUrl}api/check_verification.php";

  // IMAGES
  static const String imageBaseUrl = "${baseUrl}uploads";

  static String getCarImageUrl(String imagePath) {
    if (imagePath.isEmpty) return "";

    final cleanPath = imagePath.startsWith("/")
        ? imagePath.substring(1)
        : imagePath;

    return "$imageBaseUrl/$cleanPath";
  }

  // TIMEOUT
  static const Duration apiTimeout = Duration(seconds: 10);
}
