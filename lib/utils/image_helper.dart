import 'package:flutter/material.dart';
import 'package:cargo/widgets/optimized_network_image.dart';
import 'package:cargo/config/api_config.dart';

/// Centralized image helper utility for consistent image display across the app
/// 
/// This helper ensures:
/// - Proper URL formatting (fixes double slashes, HTTP->HTTPS)
/// - Consistent error handling
/// - Optimized caching
/// - Shimmer loading states
class ImageHelper {
  /// Build an optimized network image with automatic URL formatting
  /// 
  /// Usage:
  /// ```dart
  /// ImageHelper.buildImage(
  ///   imageUrl: car['image'],
  ///   width: 200,
  ///   height: 150,
  /// )
  /// ```
  static Widget buildImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    IconData errorIcon = Icons.broken_image,
    double errorIconSize = 50,
  }) {
    // Format the image URL using the global config
    final formattedUrl = GlobalApiConfig.getImageUrl(imageUrl);
    
    return OptimizedNetworkImage(
      imageUrl: formattedUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      errorIcon: errorIcon,
      errorIconSize: errorIconSize,
    );
  }

  /// Build a car image with proper formatting
  static Widget buildCarImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return buildImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      errorIcon: Icons.directions_car,
      errorIconSize: 60,
    );
  }

  /// Build a motorcycle image with proper formatting
  static Widget buildMotorcycleImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return buildImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      errorIcon: Icons.two_wheeler,
      errorIconSize: 60,
    );
  }

  /// Build a profile/avatar image with proper formatting
  static Widget buildProfileImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return buildImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      errorIcon: Icons.person,
      errorIconSize: 50,
    );
  }

  /// Get a properly formatted image URL (for use with Image.network or NetworkImage)
  /// 
  /// Usage:
  /// ```dart
  /// final url = ImageHelper.formatImageUrl(car['image']);
  /// Image.network(url);
  /// ```
  static String formatImageUrl(String? imageUrl) {
    final formatted = GlobalApiConfig.getImageUrl(imageUrl);
    return formatted;
  }

  /// Get a NetworkImage with properly formatted URL
  /// 
  /// Usage in CircleAvatar:
  /// ```dart
  /// CircleAvatar(
  ///   backgroundImage: ImageHelper.getNetworkImage(user['avatar']),
  /// )
  /// ```
  static ImageProvider getNetworkImage(String? imageUrl) {
    final formattedUrl = GlobalApiConfig.getImageUrl(imageUrl);
    return NetworkImage(formattedUrl);
  }
}
