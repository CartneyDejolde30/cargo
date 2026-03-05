import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/config/cache_config.dart';

/// Image preloader utility for faster navigation
/// Preloads images before user navigates to detail screens
class ImagePreloader {
  /// Preload a single image
  static Future<void> preloadImage(
    BuildContext context,
    String imageUrl, {
    bool isVehicleImage = true,
  }) async {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return;

    try {
      await precacheImage(
        CachedNetworkImageProvider(
          imageUrl,
          cacheManager: isVehicleImage 
              ? VehicleImageCacheManager.instance 
              : ProfileImageCacheManager.instance,
        ),
        context,
      );
      debugPrint('✅ Preloaded image: ${imageUrl.substring(0, 50)}...');
    } catch (e) {
      debugPrint('⚠️ Failed to preload image: $e');
    }
  }

  /// Preload multiple images (e.g., all images in a car detail screen)
  static Future<void> preloadMultipleImages(
    BuildContext context,
    List<String> imageUrls, {
    bool isVehicleImage = true,
  }) async {
    final validUrls = imageUrls.where(
      (url) => url.isNotEmpty && url.startsWith('http'),
    ).toList();

    if (validUrls.isEmpty) return;

    try {
      await Future.wait(
        validUrls.map((url) => preloadImage(context, url, isVehicleImage: isVehicleImage)),
      );
      debugPrint('✅ Preloaded ${validUrls.length} images');
    } catch (e) {
      debugPrint('⚠️ Error preloading images: $e');
    }
  }

  /// Preload vehicle images from a list (e.g., search results)
  /// Only preloads first 10 images to avoid excessive network usage
  static Future<void> preloadVehicleList(
    BuildContext context,
    List<Map<String, dynamic>> vehicles, {
    int maxImages = 10,
  }) async {
    final imageUrls = vehicles
        .take(maxImages)
        .map((vehicle) => vehicle['image']?.toString() ?? '')
        .where((url) => url.isNotEmpty && url.startsWith('http'))
        .toList();

    await preloadMultipleImages(context, imageUrls, isVehicleImage: true);
  }

  /// Preload images for car detail screen
  /// Call this when user hovers or is about to tap on a car card
  static Future<void> preloadCarDetailImages(
    BuildContext context,
    String mainImage,
    List<String>? extraImages,
  ) async {
    final images = [
      mainImage,
      if (extraImages != null) ...extraImages,
    ];

    await preloadMultipleImages(context, images, isVehicleImage: true);
  }

  /// Preload booking screen images
  static Future<void> preloadBookingImages(
    BuildContext context,
    String carImage,
    String? ownerAvatar,
  ) async {
    await Future.wait([
      preloadImage(context, carImage, isVehicleImage: true),
      if (ownerAvatar != null && ownerAvatar.isNotEmpty)
        preloadImage(context, ownerAvatar, isVehicleImage: false),
    ]);
  }

  /// Smart preloading: preload next items when user scrolls
  /// Call this in a ListView/GridView scroll listener
  static Future<void> smartPreloadOnScroll(
    BuildContext context,
    ScrollController scrollController,
    List<Map<String, dynamic>> allItems,
    int currentIndex, {
    int preloadCount = 3,
  }) async {
    // Calculate how far user has scrolled
    final scrollPercentage = scrollController.offset / scrollController.position.maxScrollExtent;

    // If user is 70% through the list, preload next items
    if (scrollPercentage > 0.7) {
      final nextIndex = currentIndex + 1;
      final endIndex = (nextIndex + preloadCount).clamp(0, allItems.length);
      
      final nextItems = allItems.sublist(nextIndex, endIndex);
      await preloadVehicleList(context, nextItems, maxImages: preloadCount);
    }
  }
}

/// Mixin for screens that need image preloading
mixin ImagePreloadingMixin<T extends StatefulWidget> on State<T> {
  /// Track if images have been preloaded
  final Set<String> _preloadedUrls = {};

  /// Preload with deduplication
  Future<void> preloadImageSafe(String imageUrl, {bool isVehicleImage = true}) async {
    if (_preloadedUrls.contains(imageUrl)) return;
    
    await ImagePreloader.preloadImage(context, imageUrl, isVehicleImage: isVehicleImage);
    _preloadedUrls.add(imageUrl);
  }

  /// Clear preloaded tracking on dispose
  @override
  void dispose() {
    _preloadedUrls.clear();
    super.dispose();
  }
}
