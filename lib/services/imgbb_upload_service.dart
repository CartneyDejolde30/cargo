import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/imgbb_config.dart';

/// Service for uploading images to ImgBB
class ImgBBUploadService {
  /// Upload an image file to ImgBB
  /// Returns the direct image URL on success
  static Future<ImgBBUploadResult> uploadImage(
    File imageFile, {
    String? name,
    int? expiration,
  }) async {
    try {
      print('📤 Starting ImgBB upload...');
      print('📁 File: ${imageFile.path}');
      
      // Check file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      // Check file size
      final fileSize = await imageFile.length();
      print('📦 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      
      if (fileSize > ImgBBConfig.maxFileSizeBytes) {
        throw Exception(
          'File too large. Max size: ${ImgBBConfig.maxFileSizeBytes / (1024 * 1024)}MB'
        );
      }
      
      // Read file as base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      print('🔄 Converting to base64... (${base64Image.length} chars)');
      
      // Prepare request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ImgBBConfig.uploadEndpoint),
      );
      
      // Add API key
      request.fields['key'] = ImgBBConfig.apiKey;
      
      // Add image as base64
      request.fields['image'] = base64Image;
      
      // Optional: Add name
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }
      
      // Optional: Add expiration (in seconds)
      if (expiration != null && expiration > 0) {
        request.fields['expiration'] = expiration.toString();
      }
      
      print('🌐 Uploading to ImgBB...');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        ImgBBConfig.uploadTimeout,
        onTimeout: () {
          throw Exception('Upload timeout after ${ImgBBConfig.uploadTimeout.inSeconds}s');
        },
      );
      
      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          
          final result = ImgBBUploadResult(
            success: true,
            url: data['url'],
            displayUrl: data['display_url'],
            deleteUrl: data['delete_url'],
            imageId: data['id'],
            title: data['title'],
            width: data['width'],
            height: data['height'],
            size: data['size'],
            thumbUrl: data['thumb']['url'],
            mediumUrl: data['medium']['url'],
          );
          
          print('✅ Upload successful!');
          print('🔗 URL: ${result.url}');
          print('📊 Size: ${data['width']}x${data['height']}');
          
          return result;
        } else {
          throw Exception('ImgBB API returned success=false');
        }
      } else {
        final errorBody = response.body;
        print('❌ Upload failed: $errorBody');
        
        // Try to parse error message
        try {
          final errorJson = json.decode(errorBody);
          final errorMessage = errorJson['error']['message'] ?? 'Unknown error';
          throw Exception('ImgBB Error: $errorMessage');
        } catch (e) {
          throw Exception('Upload failed with status ${response.statusCode}');
        }
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }
  
  /// Upload image and return only the direct URL (simplified)
  static Future<String> uploadImageSimple(File imageFile) async {
    final result = await uploadImage(imageFile);
    return result.displayUrl;
  }
}

/// Result from ImgBB upload
class ImgBBUploadResult {
  final bool success;
  final String url;
  final String displayUrl;
  final String deleteUrl;
  final String imageId;
  final String title;
  final int width;
  final int height;
  final int size;
  final String thumbUrl;
  final String mediumUrl;
  
  ImgBBUploadResult({
    required this.success,
    required this.url,
    required this.displayUrl,
    required this.deleteUrl,
    required this.imageId,
    required this.title,
    required this.width,
    required this.height,
    required this.size,
    required this.thumbUrl,
    required this.mediumUrl,
  });
  
  Map<String, dynamic> toJson() => {
    'success': success,
    'url': url,
    'display_url': displayUrl,
    'delete_url': deleteUrl,
    'id': imageId,
    'title': title,
    'width': width,
    'height': height,
    'size': size,
    'thumb_url': thumbUrl,
    'medium_url': mediumUrl,
  };
  
  @override
  String toString() => 'ImgBBUploadResult(url: $displayUrl, size: ${width}x$height)';
}
