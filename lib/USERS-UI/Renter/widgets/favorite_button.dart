import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String vehicleType; // 'car' or 'motorcycle'
  final int vehicleId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBackground;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.vehicleType,
    required this.vehicleId,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.showBackground = true,
    this.onToggle,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.vehicleType, widget.vehicleId);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Animate
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final result = await _favoritesService.toggleFavorite(widget.vehicleType, widget.vehicleId);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['status'] == 'success') {
        setState(() => _isFavorite = !_isFavorite);
        
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            duration: const Duration(seconds: 1),
            backgroundColor: _isFavorite ? Colors.green : Colors.grey.shade700,
          ),
        );

        // Call callback
        widget.onToggle?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Operation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? Colors.grey.shade400;

    Widget icon = ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? activeColor : inactiveColor,
        size: widget.size,
      ),
    );

    if (_isLoading) {
      icon = SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(activeColor),
        ),
      );
    }

    if (!widget.showBackground) {
      return GestureDetector(
        onTap: _toggleFavorite,
        child: icon,
      );
    }

    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: icon,
      ),
    );
  }
}
