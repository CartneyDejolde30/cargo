import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../analytics_models.dart';

class RevenueBreakdownChart extends StatelessWidget {
  final RevenueBreakdown breakdown;

  const RevenueBreakdownChart({
    super.key,
    required this.breakdown,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Revenue Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // By Vehicle Type
          if (breakdown.byVehicleType.isNotEmpty) ...[
            Text(
              'By Vehicle Type',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildVehicleTypeChart(),
            const SizedBox(height: 24),
          ],
          
          // By Payment Status
          if (breakdown.byPaymentStatus.isNotEmpty) ...[
            Text(
              'By Payment Status',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentStatusList(),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleTypeChart() {
    final total = breakdown.byVehicleType.fold<double>(
      0,
      (sum, item) => sum + item.revenue,
    );

    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: breakdown.byVehicleType.map((item) {
        final percentage = (item.revenue / total * 100).toStringAsFixed(1);
        final color = item.type.toLowerCase() == 'car' ? Colors.blue : Colors.orange;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.type.toLowerCase() == 'car'
                            ? Icons.directions_car
                            : Icons.two_wheeler,
                        size: 20,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.type,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${item.bookings} bookings)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(item.revenue),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.revenue / total,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentStatusList() {
    final statusColors = {
      'paid': Colors.green,
      'pending': Colors.orange,
      'failed': Colors.red,
      'refunded': Colors.purple,
    };

    return Column(
      children: breakdown.byPaymentStatus.map((item) {
        final color = statusColors[item.status.toLowerCase()] ?? Colors.grey;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${item.count} transactions',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                _formatCurrency(item.amount),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
