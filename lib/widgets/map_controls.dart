import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Map Controls Widget
/// Provides zoom in/out, compass, and center location buttons
class MapControls extends StatelessWidget {
  final MapController mapController;
  final VoidCallback? onCenterLocation;
  final double? currentZoom;
  final double? currentRotation;
  
  const MapControls({
    super.key,
    required this.mapController,
    this.onCenterLocation,
    this.currentZoom,
    this.currentRotation,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compass (shows rotation)
        if (currentRotation != null && currentRotation != 0)
          _buildControlButton(
            icon: Icons.explore,
            onPressed: () {
              mapController.rotate(0); // Reset rotation
            },
            rotation: currentRotation ?? 0,
          ),
        
        const SizedBox(height: 8),
        
        // Zoom In
        _buildControlButton(
          icon: Icons.add,
          onPressed: () {
            final zoom = mapController.camera.zoom;
            mapController.move(
              mapController.camera.center,
              zoom + 1,
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Zoom Out
        _buildControlButton(
          icon: Icons.remove,
          onPressed: () {
            final zoom = mapController.camera.zoom;
            mapController.move(
              mapController.camera.center,
              zoom - 1,
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Center on User Location
        if (onCenterLocation != null)
          _buildControlButton(
            icon: Icons.my_location,
            onPressed: onCenterLocation!,
            color: Colors.blue,
          ),
      ],
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double rotation = 0,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Material(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: rotation * (3.14159 / 180), // Convert to radians
                child: Icon(
                  icon, 
                  color: color ?? (isDark ? Colors.white : Colors.black87), 
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
