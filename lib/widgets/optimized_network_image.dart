import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cargo/config/cache_config.dart';
import 'package:cargo/config/api_config.dart';

/// Optimized network image widget with caching, placeholders, and error handling
/// 
/// This widget provides:
/// - Automatic image caching (30 days)
/// - Shimmer loading placeholder
/// - Error fallback
/// - Memory optimization
/// - Fade-in animation
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;
  final IconData errorIcon;
  final double errorIconSize;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.errorIcon = Icons.broken_image,
    this.errorIconSize = 60,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✅ FIX: Ensure image URL is properly formatted with full domain
    final formattedImageUrl = GlobalApiConfig.getImageUrl(imageUrl);
    
    // Default colors based on theme
    final baseColor = shimmerBaseColor ?? 
      (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = shimmerHighlightColor ?? 
      (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    Widget content = CachedNetworkImage(
      imageUrl: formattedImageUrl,
      width: width,
      height: height,
      fit: fit,
      
      // ✅ Use custom cache manager for better performance
      cacheManager: VehicleImageCacheManager.instance,
      
      // ✅ Shimmer loading placeholder
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: borderRadius,
          ),
        ),
      ),
      
      // ✅ Error widget
      errorWidget: (context, url, error) {
        // Suppress common non-actionable errors (missing images, decode failures)
        final errStr = error.toString();
        if (!errStr.contains('404') && !errStr.contains('EncodingError') && !errStr.contains('cannot be decoded')) {
          print('❌ Network error: $error');
        }
        return errorWidget ?? Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.grey.shade200,
            borderRadius: borderRadius,
          ),
          child: Icon(
            errorIcon,
            size: errorIconSize,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
          ),
        );
      },
      
      // ✅ Fade-in animation
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      
      // ✅ FIX: Remove maxWidth/maxHeight parameters when using custom CacheManager
      // These parameters cause assertion errors with custom CacheManager
      // The CacheManager should handle image resizing, not CachedNetworkImage
    );

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}

/// Circular avatar with optimized image loading
class OptimizedAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? errorWidget;

  const OptimizedAvatarImage({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[300],
      child: ClipOval(
        child: OptimizedNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: errorWidget ?? Icon(
            Icons.person,
            size: radius,
            color: Colors.grey,
          ),
          errorIcon: Icons.person,
          errorIconSize: radius,
        ),
      ),
    );
  }
}

/// Grid/List item optimized image with aspect ratio
class OptimizedGridImage extends StatelessWidget {
  final String imageUrl;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final Widget? badge;

  const OptimizedGridImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 1.0,
    this.borderRadius,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OptimizedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            borderRadius: borderRadius,
          ),
          if (badge != null)
            Positioned(
              top: 8,
              left: 8,
              child: badge!,
            ),
        ],
      ),
    );
  }
}
