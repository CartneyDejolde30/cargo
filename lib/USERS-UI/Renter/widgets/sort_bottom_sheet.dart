import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SortOption {
  final String label;
  final String value;
  final IconData icon;

  SortOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class SortBottomSheet extends StatelessWidget {
  final String? currentSortBy;
  final String? currentSortOrder;
  final Function(String sortBy, String sortOrder) onSortChanged;

  const SortBottomSheet({
    super.key,
    this.currentSortBy,
    this.currentSortOrder,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      SortOption(
        label: 'Price: Low to High',
        value: 'price_per_day',
        icon: Icons.arrow_upward,
      ),
      SortOption(
        label: 'Price: High to Low',
        value: 'price_per_day_desc',
        icon: Icons.arrow_downward,
      ),
      SortOption(
        label: 'Rating: Highest First',
        value: 'rating',
        icon: Icons.star,
      ),
      SortOption(
        label: 'Year: Newest First',
        value: 'year',
        icon: Icons.calendar_today,
      ),
      SortOption(
        label: 'Year: Oldest First',
        value: 'year_asc',
        icon: Icons.calendar_today_outlined,
      ),
      SortOption(
        label: 'Recently Added',
        value: 'created_at',
        icon: Icons.new_releases,
      ),
    ];

    String currentSort = currentSortBy ?? 'created_at';
    if (currentSortOrder == 'ASC' && currentSortBy == 'price_per_day') {
      currentSort = 'price_per_day';
    } else if (currentSortOrder == 'DESC' && currentSortBy == 'price_per_day') {
      currentSort = 'price_per_day_desc';
    } else if (currentSortBy == 'rating') {
      currentSort = 'rating';
    } else if (currentSortBy == 'car_year' || currentSortBy == 'motorcycle_year') {
      currentSort = currentSortOrder == 'ASC' ? 'year_asc' : 'year';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort By',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortOptions.map((option) {
            bool isSelected = currentSort == option.value;
            return InkWell(
              onTap: () {
                String sortBy;
                String sortOrder;

                switch (option.value) {
                  case 'price_per_day':
                    sortBy = 'price_per_day';
                    sortOrder = 'ASC';
                    break;
                  case 'price_per_day_desc':
                    sortBy = 'price_per_day';
                    sortOrder = 'DESC';
                    break;
                  case 'rating':
                    sortBy = 'rating';
                    sortOrder = 'DESC';
                    break;
                  case 'year':
                    sortBy = 'year';
                    sortOrder = 'DESC';
                    break;
                  case 'year_asc':
                    sortBy = 'year';
                    sortOrder = 'ASC';
                    break;
                  case 'created_at':
                  default:
                    sortBy = 'created_at';
                    sortOrder = 'DESC';
                    break;
                }

                onSortChanged(sortBy, sortOrder);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      color: isSelected
                          ? Theme.of(context).iconTheme.color
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option.label,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? Theme.of(context).iconTheme.color
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).iconTheme.color,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
