import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/maptiler_config.dart';

/// MapTiler Geocoding Service
/// Handles address search, autocomplete, and reverse geocoding
class MapTilerGeocodingService {
  /// Search for places by query
  /// Returns list of place suggestions with coordinates
  static Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final url = MapTilerConfig.getGeocodingUrl(query);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        return features.map((feature) {
          final coords = feature['geometry']['coordinates'] as List;
          return Place(
            name: feature['place_name'] ?? feature['text'] ?? '',
            address: feature['place_name'] ?? '',
            coordinates: LatLng(coords[1], coords[0]), // lat, lng
            placeType: feature['place_type']?.first ?? '',
            context: _extractContext(feature['context']),
          );
        }).toList();
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
    }
    
    return [];
  }
  
  /// Reverse geocoding - get address from coordinates
  static Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final url = MapTilerConfig.getReverseGeocodingUrl(
        coordinates.longitude,
        coordinates.latitude,
      );
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        if (features.isNotEmpty) {
          return features.first['place_name'] as String?;
        }
      }
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
    }
    
    return null;
  }
  
  /// Extract context information (city, region, country)
  static Map<String, String> _extractContext(List? context) {
    final result = <String, String>{};
    
    if (context == null) return result;
    
    for (var item in context) {
      final id = item['id'] as String?;
      final text = item['text'] as String?;
      
      if (id != null && text != null) {
        if (id.startsWith('place')) {
          result['city'] = text;
        } else if (id.startsWith('region')) {
          result['region'] = text;
        } else if (id.startsWith('country')) {
          result['country'] = text;
        }
      }
    }
    
    return result;
  }
}

/// Place data model
class Place {
  final String name;
  final String address;
  final LatLng coordinates;
  final String placeType;
  final Map<String, String> context;
  
  const Place({
    required this.name,
    required this.address,
    required this.coordinates,
    required this.placeType,
    required this.context,
  });
  
  String get displayName => name.isNotEmpty ? name : address;
  String get city => context['city'] ?? '';
  String get region => context['region'] ?? '';
  String get country => context['country'] ?? '';
}
