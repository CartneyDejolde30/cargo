import 'package:http/http.dart' as http;
import 'dart:async';

/// Simple network checker to diagnose image loading issues
class NetworkChecker {
  /// Test if ImgBB CDN is reachable
  static Future<NetworkStatus> checkImgBBConnection() async {
    try {
      print('🔍 Testing ImgBB connectivity...');
      
      final stopwatch = Stopwatch()..start();
      final response = await http.head(
        Uri.parse('https://i.ibb.co'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ ImgBB connection timed out');
          throw TimeoutException('Connection timeout');
        },
      );
      stopwatch.stop();
      
      print('✓ ImgBB reachable in ${stopwatch.elapsedMilliseconds}ms');
      print('✓ Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 301 || response.statusCode == 302) {
        if (stopwatch.elapsedMilliseconds < 3000) {
          return NetworkStatus.good;
        } else {
          return NetworkStatus.slow;
        }
      } else {
        return NetworkStatus.blocked;
      }
    } on TimeoutException {
      print('❌ Connection timeout - network too slow or unreachable');
      return NetworkStatus.timeout;
    } catch (e) {
      print('❌ Network error: $e');
      return NetworkStatus.offline;
    }
  }
  
  /// Get user-friendly message for network status
  static String getStatusMessage(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.good:
        return '✓ Connection is good';
      case NetworkStatus.slow:
        return '⚠️ Connection is slow (3+ seconds)';
      case NetworkStatus.timeout:
        return '❌ Connection timeout - check your internet';
      case NetworkStatus.blocked:
        return '❌ ImgBB may be blocked by your network';
      case NetworkStatus.offline:
        return '❌ No internet connection';
    }
  }
  
  /// Get suggested action for network status
  static String getSuggestedAction(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.good:
        return 'Images should load quickly';
      case NetworkStatus.slow:
        return 'Images may take longer to load. Be patient or switch networks.';
      case NetworkStatus.timeout:
        return 'Try switching between WiFi and mobile data';
      case NetworkStatus.blocked:
        return 'Try using a VPN or different network';
      case NetworkStatus.offline:
        return 'Connect to WiFi or mobile data';
    }
  }
}

enum NetworkStatus {
  good,      // < 3s response
  slow,      // 3-10s response
  timeout,   // > 10s no response
  blocked,   // Received error response
  offline,   // No connection
}
