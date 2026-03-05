import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cargo/config/api_config.dart';

/// Debug service to help troubleshoot favorites issues
class DebugFavoritesService {
  
  /// Get detailed debug info about favorites
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    Map<String, dynamic> debugInfo = {
      'user_id_from_prefs': userId,
      'base_url': GlobalApiConfig.baseUrl,
      'api_endpoint': '${GlobalApiConfig.baseUrl}api/favorites/get_favorites.php',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (userId != null) {
      try {
        // Test get favorites API
        final url = '${GlobalApiConfig.baseUrl}api/favorites/get_favorites.php?user_id=$userId';
        debugInfo['full_url'] = url;
        
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );
        
        debugInfo['response_status'] = response.statusCode;
        debugInfo['response_body'] = response.body;
        
        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            debugInfo['parsed_response'] = data;
            debugInfo['favorites_count'] = data['favorites']?.length ?? 0;
          } catch (e) {
            debugInfo['json_parse_error'] = e.toString();
          }
        }
      } catch (e) {
        debugInfo['network_error'] = e.toString();
      }
      
      // Test debug endpoint
      try {
        final debugUrl = '${GlobalApiConfig.baseUrl}api/favorites/debug_get_favorites.php?user_id=$userId';
        final debugResponse = await http.get(Uri.parse(debugUrl)).timeout(
          const Duration(seconds: 10),
        );
        
        if (debugResponse.statusCode == 200) {
          debugInfo['debug_endpoint_response'] = jsonDecode(debugResponse.body);
        }
      } catch (e) {
        debugInfo['debug_endpoint_error'] = e.toString();
      }
    }
    
    return debugInfo;
  }
  
  /// Print debug info to console
  static Future<void> printDebugInfo() async {
    final info = await getDebugInfo();
    print('=== FAVORITES DEBUG INFO ===');
    print(JsonEncoder.withIndent('  ').convert(info));
    print('=== END DEBUG INFO ===');
  }
}
