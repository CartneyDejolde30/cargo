import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../analytics_models.dart';

class BookingTrendsChart extends StatelessWidget {
  final List<BookingTrend> trends;

  const BookingTrendsChart({
    super.key,
    required this.trends,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) return const SizedBox.shrink();

    final maxValue = trends.map((t) => t.total).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Booking Trends',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Last 6 months',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: trends.map((trend) {
                return _buildBar(trend, maxValue, context);
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Completed', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Cancelled', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BookingTrend trend, double maxValue, BuildContext context) {
    final completedHeight = maxValue > 0 ? (trend.completed / maxValue) * 150 : 0.0;
    final cancelledHeight = maxValue > 0 ? (trend.cancelled / maxValue) * 150 : 0.0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => _showTrendDetails(context, trend),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total count badge
              if (trend.total > 0)
                Container(
                  constraints: const BoxConstraints(minHeight: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${trend.total}',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),
              const SizedBox(height: 4),
              
              // Bars
              Flexible(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Completed bar
                    Container(
                      width: double.infinity,
                      height: completedHeight.clamp(0, 150),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    // Cancelled bar (stacked on top)
                    if (trend.cancelled > 0)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 30,
                          height: cancelledHeight.clamp(0, 150),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade300, Colors.red.shade500],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Month label
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  trend.monthName.split(' ')[0],
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showTrendDetails(BuildContext context, BookingTrend trend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trend.monthName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Total Bookings', trend.total.toString(), Colors.blue),
            _buildDetailRow('Completed', trend.completed.toString(), Colors.green),
            _buildDetailRow('Cancelled', trend.cancelled.toString(), Colors.red),
            _buildDetailRow('Revenue', _formatCurrency(trend.revenue), Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
