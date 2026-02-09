import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Custom cache manager for chat images with longer cache duration and timeout handling
class ChatImageCacheManager {
  static const key = 'chatImageCache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Cache for 30 days
      maxNrOfCacheObjects: 200, // Store up to 200 images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: CustomHttpFileService(),
    ),
  );
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
      if (retryCount == 0) {
        print('🌐 Fetching image: $url');
      } else {
        print('🔄 Retry attempt $retryCount/$maxRetries for: $url');
      }
      print('⏱️ Timeout set to 45 seconds');
      
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
      
      print('✓ Response received: ${streamedResponse.statusCode}');
      
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
      print('❌ Network error: $e');
      
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
