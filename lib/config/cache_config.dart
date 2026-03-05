import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Custom cache manager for chat images with longer cache duration and timeout handling
class ChatImageCacheManager {
  static const key = 'chatImageCache';
  
  static CacheManager get instance {
    // ✅ FIX: For web platform, use in-memory cache manager (no repo needed)
    if (kIsWeb) {
      return CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 1), // Shorter cache for web
          maxNrOfCacheObjects: 100, // Less objects for web
          fileService: CustomHttpFileService(),
        ),
      );
    }
    
    // For mobile/desktop platforms, use persistent cache with database
    return CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30), // Cache for 30 days
        maxNrOfCacheObjects: 200, // Store up to 200 images
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: CustomHttpFileService(),
      ),
    );
  }
}

/// ✅ NEW: Optimized cache manager for vehicle images (cars/motorcycles)
/// Longer cache period, more objects, optimized for thumbnails
class VehicleImageCacheManager {
  static const key = 'vehicleImageCache';
  
  static CacheManager get instance {
    // ✅ FIX: For web platform, use in-memory cache manager (no repo needed)
    if (kIsWeb) {
      return CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 1), // Shorter cache for web
          maxNrOfCacheObjects: 200, // Less objects for web
          fileService: CustomHttpFileService(),
        ),
      );
    }
    
    // For mobile/desktop platforms, use persistent cache with database
    return CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 60), // Cache for 60 days (vehicles don't change often)
        maxNrOfCacheObjects: 500, // Store up to 500 vehicle images
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: CustomHttpFileService(),
      ),
    );
  }
  
  /// Clear cache manually if needed
  static Future<void> clearCache() async {
    await instance.emptyCache();
    print('✅ Vehicle image cache cleared');
  }
  
  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      // ✅ FIX: Handle web platform gracefully
      if (kIsWeb) {
        return 0; // Web doesn't persist cache
      }
      final files = await instance.store.retrieveCacheData('');
      return files?.length ?? 0;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }
}

/// ✅ NEW: Cache manager for profile/avatar images
class ProfileImageCacheManager {
  static const key = 'profileImageCache';
  
  static CacheManager get instance {
    // ✅ FIX: For web platform, use in-memory cache manager (no repo needed)
    if (kIsWeb) {
      return CacheManager(
        Config(
          key,
          stalePeriod: const Duration(hours: 12), // Shorter cache for web
          maxNrOfCacheObjects: 50, // Less objects for web
          fileService: CustomHttpFileService(),
        ),
      );
    }
    
    // For mobile/desktop platforms, use persistent cache with database
    return CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7), // Profile images change more often
        maxNrOfCacheObjects: 100,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: CustomHttpFileService(),
      ),
    );
  }
}

/// Custom HTTP file service with extended timeout and retry logic
class CustomHttpFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    return _getWithRetry(url, headers: headers, retryCount: 0);
  }
  
  Future<FileServiceResponse> _getWithRetry(
    String url, {
    Map<String, String>? headers,
    required int retryCount,
  }) async {
    const maxRetries = 3;
    final client = http.Client();
    
    try {
      // Only log retries, not every single image fetch (reduces console spam)
      if (retryCount > 0) {
        print('🔄 Retry attempt $retryCount/$maxRetries for: $url');
      }
      
      final request = http.Request('GET', Uri.parse(url));
      
      // Add headers to prevent blocking by CDNs
      request.headers.addAll({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Cache-Control': 'no-cache',
        ...?headers,
      });
      
      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 45), // Increased from 30s to 45s
        onTimeout: () {
          print('❌ Request timeout after 45 seconds for: $url');
          throw TimeoutException('Connection timeout');
        },
      );
      
      if (streamedResponse.statusCode == 200) {
        // Wrap the stream to detect connection drops during download
        final wrappedStream = streamedResponse.stream.timeout(
          const Duration(seconds: 30),
          onTimeout: (sink) {
            print('❌ Connection dropped during download');
            sink.addError(TimeoutException('Download interrupted'));
          },
        );
        
        final modifiedResponse = http.StreamedResponse(
          wrappedStream,
          streamedResponse.statusCode,
          headers: streamedResponse.headers,
          request: streamedResponse.request,
          isRedirect: streamedResponse.isRedirect,
          persistentConnection: streamedResponse.persistentConnection,
          reasonPhrase: streamedResponse.reasonPhrase,
        );
        
        return HttpGetResponse(modifiedResponse);
      } else {
        throw HttpExceptionWithStatus(
          streamedResponse.statusCode,
          'HTTP Error ${streamedResponse.statusCode}',
          uri: Uri.parse(url),
        );
      }
    } catch (e) {
      // Only log network errors, not 404s (missing images are common)
      if (!e.toString().contains('404')) {
        print('❌ Network error: $e');
      }
      
      // Retry logic for connection issues
      if (retryCount < maxRetries) {
        final shouldRetry = e.toString().contains('Connection timed out') ||
                           e.toString().contains('Connection closed') ||
                           e.toString().contains('Connection reset') ||
                           e.toString().contains('SocketException');
        
        if (shouldRetry) {
          // Exponential backoff: 2s, 4s, 8s
          final delaySeconds = 2 * (retryCount + 1);
          print('⏳ Waiting ${delaySeconds}s before retry...');
          await Future.delayed(Duration(seconds: delaySeconds));
          client.close();
          return _getWithRetry(url, headers: headers, retryCount: retryCount + 1);
        }
      }
      
      client.close();
      rethrow;
    }
  }
}
