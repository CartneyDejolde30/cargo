import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingTabsWidget extends StatelessWidget {
  final int currentTabIndex;
  final Function(int) onTabChanged;
  final List<String> tabs;
  final List<int>? badgeCounts;

  const BookingTabsWidget({
    super.key,
    required this.currentTabIndex,
    required this.onTabChanged,
    this.tabs = const ['Active', 'Pending', 'Completed', 'Rejected'],
    this.badgeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => _buildTab(
            label: tabs[index],
            index: index,
            badgeCount: badgeCounts != null && index < badgeCounts!.length
                ? badgeCounts![index]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required int index,
    int? badgeCount,
  }) {
    bool isSelected = currentTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5, // Reduced from 13
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Badge
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -6,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}