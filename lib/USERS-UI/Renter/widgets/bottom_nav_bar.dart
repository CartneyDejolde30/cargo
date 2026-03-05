import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });


  void _handleNavigation(BuildContext context, int index) {
    // Call the onTap callback first
    onTap(index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/renters');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/my_bookings');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/favorites');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/chat_list');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(context, Icons.home_rounded, 0, currentIndex == 0),
              _buildNavItem(context, Icons.book, 1, currentIndex == 1),
              _buildNavItem(context, Icons.favorite_border, 2, currentIndex == 2),
              _buildNavItem(context, Icons.chat_bubble_outline_rounded, 3, currentIndex == 3),
              _buildNavItem(context, Icons.person_outline_rounded, 4, currentIndex == 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, int index, bool isActive) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }
}
