import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/maptiler_config.dart';

/// Map Style Switcher Widget
/// Allows users to switch between different map styles
class MapStyleSwitcher extends StatelessWidget {
  final String currentStyle;
  final Function(String) onStyleChanged;
  
  const MapStyleSwitcher({
    super.key,
    required this.currentStyle,
    required this.onStyleChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200, // Fixed width to prevent unbounded constraints
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Style',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...MapTilerConfig.getAllStyles().map((style) {
              final isSelected = style.id == currentStyle;
              return _buildStyleOption(
                emoji: style.emoji,
                name: style.name,
                isSelected: isSelected,
                onTap: () => onStyleChanged(style.id),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStyleOption({
    required String emoji,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                      ? Colors.blue 
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                            ? Colors.blue 
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
