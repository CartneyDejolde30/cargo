import 'package:flutter_application_1/config/api_config.dart';

class ApiConstants {
  // ========================================
  // CENTRALIZED CONFIGURATION
  // All URLs now come from GlobalApiConfig
  // Change environment in lib/config/api_config.dart
  // ========================================
  
  static String get baseUrl => GlobalApiConfig.baseUrl + '/';

  // APIs
  static String get carsApi => GlobalApiConfig.carsApiEndpoint;
  static String get checkVerificationApi => GlobalApiConfig.checkVerificationEndpoint;

  // IMAGES
  static String get imageBaseUrl => GlobalApiConfig.uploadsUrl;

  static String getCarImageUrl(String imagePath) {
    return GlobalApiConfig.getCarImageUrl(imagePath);
  }

  // TIMEOUT
  static Duration get apiTimeout => GlobalApiConfig.apiTimeout;
}
