import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../analytics_models.dart';

class OverviewStatsWidget extends StatelessWidget {
  final AnalyticsOverview overview;

  const OverviewStatsWidget({
    super.key,
    required this.overview,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            _buildStatCard(
              title: 'Total Bookings',
              value: overview.totalBookings.toString(),
              icon: Icons.calendar_today,
              color: Colors.blue,
              subtitle: '${overview.completedBookings} completed',
            ),
            _buildStatCard(
              title: 'Total Revenue',
              value: _formatCurrency(overview.totalRevenue),
              icon: Icons.attach_money,
              color: Colors.green,
              subtitle: 'All time earnings',
            ),
            _buildStatCard(
              title: 'Active Vehicles',
              value: overview.activeVehicles.toString(),
              icon: Icons.directions_car,
              color: Colors.orange,
              subtitle: '${overview.activeCars} cars, ${overview.activeMotorcycles} bikes',
            ),
            _buildStatCard(
              title: 'Completion Rate',
              value: '${overview.completionRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.purple,
              subtitle: '${overview.averageRating.toStringAsFixed(1)} ⭐ avg rating',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.grey[500],
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
