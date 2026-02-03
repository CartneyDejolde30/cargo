/// MapTiler Configuration
/// Centralized configuration for all MapTiler integration
/// This ensures consistency across the app and makes updates easier

class MapTilerConfig {
  // API Key - Consider moving to environment variables in production
  static const String apiKey = 'YGJxmPnRtlTHI1endzDH';
  
  // Base URLs
  static const String baseUrl = 'https://api.maptiler.com';
  static const String mapsBaseUrl = '$baseUrl/maps';
  static const String geocodingBaseUrl = '$baseUrl/geocoding';
  static const String navigationBaseUrl = '$baseUrl/navigation';
  
  // Available Map Styles (MapTiler API style IDs)
  static const String streetsStyle = 'streets-v2';
  static const String satelliteStyle = 'satellite';
  static const String darkStyle = 'streets-v2-dark';
  static const String outdoorStyle = 'outdoor-v2';
  static const String basicStyle = 'basic-v2';
  static const String brightStyle = 'bright-v2';
  
  // Default style
  static const String defaultStyle = streetsStyle;
  
  // Map Configuration
  static const double defaultZoom = 12.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;
  static const double defaultMarkerSize = 40.0;
  
  // Location Configuration
  static const double arrivalRadiusMeters = 100.0; // Geofence radius
  static const int locationUpdateIntervalSeconds = 10;
  
  // Routing Configuration
  static const String routingProfile = 'driving'; // driving, walking, cycling
  
  /// Get tile URL for a specific style
  static String getTileUrl(String style) {
    return '$mapsBaseUrl/$style/{z}/{x}/{y}.png?key=$apiKey';
  }
  
  /// Get geocoding URL for place search
  static String getGeocodingUrl(String query) {
    return '$geocodingBaseUrl/$query.json?key=$apiKey';
  }
  
  /// Get reverse geocoding URL
  static String getReverseGeocodingUrl(double lng, double lat) {
    return '$geocodingBaseUrl/$lng,$lat.json?key=$apiKey';
  }
  
  /// Get navigation/routing URL
  static String getNavigationUrl(
    double startLng,
    double startLat,
    double endLng,
    double endLat, {
    String profile = 'driving',
  }) {
    return '$navigationBaseUrl/$profile/$startLng,$startLat;$endLng,$endLat.json?key=$apiKey';
  }
  
  /// Get style display name
  static String getStyleDisplayName(String style) {
    switch (style) {
      case streetsStyle:
        return 'Streets';
      case satelliteStyle:
        return 'Satellite';
      case darkStyle:
        return 'Dark';
      case outdoorStyle:
        return 'Outdoor';
      case basicStyle:
        return 'Basic';
      case brightStyle:
        return 'Bright';
      default:
        return 'Unknown';
    }
  }
  
  /// Get all available styles
  static List<MapStyle> getAllStyles() {
    return [
      MapStyle(streetsStyle, 'Streets', '🗺️'),
      MapStyle(satelliteStyle, 'Satellite', '🛰️'),
      MapStyle(outdoorStyle, 'Outdoor', '🏞️'),
      MapStyle(darkStyle, 'Dark', '🌙'),
    ];
  }
}

/// Map style data class
class MapStyle {
  final String id;
  final String name;
  final String emoji;
  
  const MapStyle(this.id, this.name, this.emoji);
}
