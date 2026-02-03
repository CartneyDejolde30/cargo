import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './booking_model.dart';
import '../../Owner/mycar/api_constants.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<Booking> recentBookings;

  const RecentActivityWidget({
    super.key,
    required this.recentBookings,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (recentBookings.isEmpty) {
      return _buildEmptyState(context, isDark, colors);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : colors.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Activity",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
              ),
              Icon(
                Icons.history,
                color: isDark
                    ? colors.primary
                    : Colors.grey.shade600,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentBookings.map(
            (booking) => _buildActivityItem(
              context,
              booking,
              isDark,
              colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    Booking booking,
    bool isDark,
    ColorScheme colors,
  ) {
    debugPrint("🖼 IMAGE URL: ${ApiConstants.getCarImageUrl(booking.carImage)}");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surface.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Car Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              ApiConstants.getCarImageUrl(booking.carImage),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: isDark
                    ? colors.surface
                    : Colors.grey.shade300,
                child: Icon(
                  Icons.directions_car,
                  color: isDark
                      ? colors.onSurface.withOpacity(0.7)
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Booking Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.carFullName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  booking.renterName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(booking.startDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(
                isDark ? 0.2 : 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getStatusColor(booking.status).withOpacity(
                  isDark ? 0.5 : 0.3,
                ),
                width: 1,
              ),
            ),
            child: Text(
              booking.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(booking.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : colors.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: isDark
                  ? colors.onSurface.withOpacity(0.6)
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              "No recent activity",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "Bookings will appear here",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
