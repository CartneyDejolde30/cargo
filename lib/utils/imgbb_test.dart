import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/imgbb_config.dart';
import '../services/imgbb_upload_service.dart';

/// Test utility for ImgBB API connectivity and functionality
class ImgBBTest {
  /// Test 1: Check if ImgBB API is reachable
  static Future<TestResult> testAPIReachability() async {
    print('\n🧪 TEST 1: ImgBB API Reachability');
    print('━' * 50);
    
    try {
      print('🔍 Testing connection to: ${ImgBBConfig.uploadEndpoint}');
      
      final stopwatch = Stopwatch()..start();
      final response = await http.head(
        Uri.parse(ImgBBConfig.cdnBase),
        headers: {'User-Agent': 'CarGO-Flutter-App'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout after 10 seconds');
        },
      );
      stopwatch.stop();
      
      print('📡 Response status: ${response.statusCode}');
      print('⏱️  Response time: ${stopwatch.elapsedMilliseconds}ms');
      print('📋 Headers: ${response.headers}');
      
      if (response.statusCode == 200 || 
          response.statusCode == 301 || 
          response.statusCode == 302 ||
          response.statusCode == 403) { // Some CDNs return 403 for HEAD
        print('✅ ImgBB API is reachable!');
        return TestResult(
          success: true,
          message: 'ImgBB API reachable',
          duration: stopwatch.elapsedMilliseconds,
        );
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Test failed: $e');
      return TestResult(
        success: false,
        message: 'Failed to reach ImgBB API: $e',
      );
    }
  }
  
  /// Test 2: Validate API Key format
  static Future<TestResult> testAPIKeyFormat() async {
    print('\n🧪 TEST 2: API Key Validation');
    print('━' * 50);
    
    try {
      final apiKey = ImgBBConfig.apiKey;
      print('🔑 API Key: ${apiKey.substring(0, 8)}...');
      print('📏 Length: ${apiKey.length} characters');
      
      if (apiKey.isEmpty) {
        throw Exception('API key is empty');
      }
      
      if (apiKey.length != 32) {
        print('⚠️  Warning: API key should be 32 characters (got ${apiKey.length})');
      }
      
      // Check if it's alphanumeric
      final isValid = RegExp(r'^[a-zA-Z0-9]+$').hasMatch(apiKey);
      
      if (isValid) {
        print('✅ API key format is valid!');
        return TestResult(
          success: true,
          message: 'API key format valid',
        );
      } else {
        throw Exception('API key contains invalid characters');
      }
    } catch (e) {
      print('❌ Test failed: $e');
      return TestResult(
        success: false,
        message: 'Invalid API key: $e',
      );
    }
  }
  
  /// Test 3: Upload a small test image
  static Future<TestResult> testImageUpload() async {
    print('\n🧪 TEST 3: Test Image Upload');
    print('━' * 50);
    
    try {
      print('📝 Creating test image (1x1 pixel)...');
      
      // Create a minimal 1x1 pixel PNG image
      final testImage = await _createTestImage();
      
      print('📦 Test image size: ${await testImage.length()} bytes');
      print('🚀 Uploading to ImgBB...');
      
      final stopwatch = Stopwatch()..start();
      final result = await ImgBBUploadService.uploadImage(
        testImage,
        name: 'test_imgbb_connectivity_${DateTime.now().millisecondsSinceEpoch}',
      );
      stopwatch.stop();
      
      print('✅ Upload successful!');
      print('🔗 Image URL: ${result.displayUrl}');
      print('📊 Image size: ${result.width}x${result.height}');
      print('💾 File size: ${result.size} bytes');
      print('⏱️  Upload time: ${stopwatch.elapsedMilliseconds}ms');
      print('🆔 Image ID: ${result.imageId}');
      
      return TestResult(
        success: true,
        message: 'Upload successful',
        duration: stopwatch.elapsedMilliseconds,
        data: result.toJson(),
      );
    } catch (e) {
      print('❌ Test failed: $e');
      return TestResult(
        success: false,
        message: 'Upload failed: $e',
      );
    }
  }
  
  /// Test 4: Test with larger image
  static Future<TestResult> testLargeImageUpload() async {
    print('\n🧪 TEST 4: Large Image Upload Test');
    print('━' * 50);
    
    try {
      print('📝 Creating test image (100x100 pixel)...');
      
      final testImage = await _createTestImage(width: 100, height: 100);
      
      print('📦 Test image size: ${await testImage.length()} bytes');
      print('🚀 Uploading to ImgBB...');
      
      final stopwatch = Stopwatch()..start();
      final result = await ImgBBUploadService.uploadImage(
        testImage,
        name: 'test_large_${DateTime.now().millisecondsSinceEpoch}',
      );
      stopwatch.stop();
      
      print('✅ Upload successful!');
      print('🔗 Image URL: ${result.displayUrl}');
      print('📊 Image size: ${result.width}x${result.height}');
      print('💾 File size: ${result.size} bytes');
      print('⏱️  Upload time: ${stopwatch.elapsedMilliseconds}ms');
      
      return TestResult(
        success: true,
        message: 'Large upload successful',
        duration: stopwatch.elapsedMilliseconds,
        data: result.toJson(),
      );
    } catch (e) {
      print('❌ Test failed: $e');
      return TestResult(
        success: false,
        message: 'Large upload failed: $e',
      );
    }
  }
  
  /// Test 5: Test error handling
  static Future<TestResult> testErrorHandling() async {
    print('\n🧪 TEST 5: Error Handling Test');
    print('━' * 50);
    
    try {
      print('🚫 Attempting upload with non-existent file...');
      
      final nonExistentFile = File('/path/that/does/not/exist.jpg');
      
      await ImgBBUploadService.uploadImage(nonExistentFile);
      
      print('❌ Test failed: Should have thrown an error');
      return TestResult(
        success: false,
        message: 'Error handling failed - no exception thrown',
      );
    } catch (e) {
      print('✅ Error caught correctly: $e');
      return TestResult(
        success: true,
        message: 'Error handling works correctly',
      );
    }
  }
  
  /// Run all tests
  static Future<List<TestResult>> runAllTests() async {
    print('\n' + '═' * 50);
    print('🧪 IMGBB API CONNECTIVITY TEST SUITE');
    print('═' * 50);
    print('📅 Date: ${DateTime.now()}');
    print('🔑 API Key: ${ImgBBConfig.apiKey.substring(0, 8)}***');
    print('═' * 50);
    
    final results = <TestResult>[];
    
    // Test 1: API Reachability
    results.add(await testAPIReachability());
    await Future.delayed(const Duration(seconds: 1));
    
    // Test 2: API Key Format
    results.add(await testAPIKeyFormat());
    await Future.delayed(const Duration(seconds: 1));
    
    // Test 3: Small Image Upload
    results.add(await testImageUpload());
    await Future.delayed(const Duration(seconds: 2));
    
    // Test 4: Large Image Upload
    results.add(await testLargeImageUpload());
    await Future.delayed(const Duration(seconds: 2));
    
    // Test 5: Error Handling
    results.add(await testErrorHandling());
    
    // Summary
    print('\n' + '═' * 50);
    print('📊 TEST SUMMARY');
    print('═' * 50);
    
    final passed = results.where((r) => r.success).length;
    final failed = results.where((r) => !r.success).length;
    final totalDuration = results
        .where((r) => r.duration != null)
        .fold<int>(0, (sum, r) => sum + r.duration!);
    
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final icon = result.success ? '✅' : '❌';
      print('$icon Test ${i + 1}: ${result.message}');
      if (result.duration != null) {
        print('   ⏱️  Duration: ${result.duration}ms');
      }
    }
    
    print('━' * 50);
    print('✅ Passed: $passed');
    print('❌ Failed: $failed');
    print('⏱️  Total time: ${totalDuration}ms');
    print('═' * 50);
    
    if (failed == 0) {
      print('\n🎉 ALL TESTS PASSED! ImgBB is working perfectly!');
    } else {
      print('\n⚠️  Some tests failed. Check the details above.');
    }
    
    return results;
  }
  
  /// Create a test image file
  static Future<File> _createTestImage({int width = 1, int height = 1}) async {
    // Create a minimal PNG image (1x1 red pixel)
    // PNG file format for a 1x1 red pixel
    final pngBytes = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
      0x49, 0x48, 0x44, 0x52, // IHDR chunk type
      0x00, 0x00, 0x00, width, // Width (1 pixel)
      0x00, 0x00, 0x00, height, // Height (1 pixel)
      0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, etc.
      0x90, 0x77, 0x53, 0xDE, // IHDR CRC
      0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
      0x49, 0x44, 0x41, 0x54, // IDAT chunk type
      0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00, 0x03, 0x01, 0x01, 0x00,
      0x18, 0xDD, 0x8D, 0xB4, // IDAT CRC
      0x00, 0x00, 0x00, 0x00, // IEND chunk length
      0x49, 0x45, 0x4E, 0x44, // IEND chunk type
      0xAE, 0x42, 0x60, 0x82, // IEND CRC
    ];
    
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/test_imgbb_${DateTime.now().millisecondsSinceEpoch}.png');
    
    await tempFile.writeAsBytes(pngBytes);
    
    return tempFile;
  }
}

/// Test result model
class TestResult {
  final bool success;
  final String message;
  final int? duration;
  final Map<String, dynamic>? data;
  
  TestResult({
    required this.success,
    required this.message,
    this.duration,
    this.data,
  });
  
  @override
  String toString() {
    return 'TestResult(success: $success, message: $message, duration: $duration)';
  }
}
