import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized loading widgets for consistent UI across the app
/// 
/// Usage Examples:
/// 1. Full-screen loading: LoadingScreen()
/// 2. Button loading: LoadingButton(isLoading: _isLoading, onPressed: _submit, text: 'Submit')
/// 3. Dialog loading: LoadingDialog.show(context)
/// 4. Inline loading: LoadingIndicator()

// ============================================================================
// PRIMARY LOADING INDICATOR
// ============================================================================

/// Standard loading indicator used throughout the app
class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double strokeWidth;
  final double? size;

  const LoadingIndicator({
    Key? key,
    this.color,
    this.strokeWidth = 2.5,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      color: color ?? Theme.of(context).primaryColor,
      strokeWidth: strokeWidth,
    );

    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: indicator,
      );
    }

    return indicator;
  }
}

// ============================================================================
// FULL-SCREEN LOADING
// ============================================================================

/// Full-screen centered loading indicator
/// Use this for initial data loading states
class LoadingScreen extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingScreen({
    Key? key,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(color: color),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// LOADING OVERLAY
// ============================================================================

/// Semi-transparent overlay with loading indicator
/// Use this for operations on top of existing content
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    Key? key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingIndicator(color: indicatorColor),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING BUTTON
// ============================================================================

/// Elevated button with built-in loading state
/// Shows loading indicator when isLoading is true
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? loadingColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isOutlined;

  const LoadingButton({
    Key? key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.loadingColor,
    this.width,
    this.height = 50,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.primaryColor;
    final effectiveForegroundColor = foregroundColor ?? Colors.white;
    final effectiveLoadingColor = loadingColor ?? effectiveForegroundColor;

    Widget buttonChild;
    
    if (isLoading) {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: LoadingIndicator(
              color: effectiveLoadingColor,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing...',
            style: GoogleFonts.poppins(
              color: effectiveForegroundColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: effectiveForegroundColor,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Text(
            text,
            style: GoogleFonts.poppins(
              color: effectiveForegroundColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: effectiveBackgroundColor,
              side: BorderSide(
                color: isLoading
                    ? Colors.grey.shade300
                    : effectiveBackgroundColor,
                width: 2,
              ),
              padding: padding,
              minimumSize: Size(width ?? double.infinity, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              disabledForegroundColor: Colors.grey.shade400,
            ),
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: effectiveBackgroundColor,
              foregroundColor: effectiveForegroundColor,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: padding,
              minimumSize: Size(width ?? double.infinity, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: 0,
            ),
            child: buttonChild,
          );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}

// ============================================================================
// LOADING DIALOG
// ============================================================================

/// Modal dialog with loading indicator
/// Non-dismissible by default
class LoadingDialog {
  /// Show a loading dialog
  static void show(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return PopScope(
          canPop: barrierDismissible,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show a simple centered loading indicator (legacy style)
  static void showSimple(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: LoadingIndicator(color: Colors.white),
        );
      },
    );
  }

  /// Hide the loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

// ============================================================================
// LINEAR PROGRESS LOADING
// ============================================================================

/// Linear progress indicator for top-of-screen loading
/// Use this for background operations where the UI remains interactive
class LinearLoadingBar extends StatelessWidget {
  final bool isLoading;
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const LinearLoadingBar({
    Key? key,
    required this.isLoading,
    this.color,
    this.backgroundColor,
    this.height = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: LinearProgressIndicator(
        color: color ?? Theme.of(context).primaryColor,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
      ),
    );
  }
}

// ============================================================================
// SHIMMER LOADING (for list items)
// ============================================================================

/// Shimmer loading effect for list items
/// Use this for skeleton screens while loading lists
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// LOADING STATE WRAPPER
// ============================================================================

/// Widget that handles loading, error, and success states
class LoadingStateBuilder<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final T? data;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final String? loadingMessage;

  const LoadingStateBuilder({
    Key? key,
    required this.isLoading,
    required this.error,
    required this.data,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.loadingMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingBuilder?.call(context) ??
          LoadingScreen(message: loadingMessage);
    }

    if (error != null) {
      return errorBuilder?.call(context, error!) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    return builder(context, data!);
  }
}
