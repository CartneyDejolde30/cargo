import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RevenueOverview extends StatelessWidget {
  final double totalIncome;
  final double monthlyIncome;
  final double weeklyIncome;
  final double todayIncome;

  const RevenueOverview({
    super.key,
    required this.totalIncome,
    required this.monthlyIncome,
    required this.weeklyIncome,
    required this.todayIncome,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : colors.surface,
        borderRadius: BorderRadius.circular(24),
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                "Revenue Overview",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
              ),
              Icon(
                Icons.trending_up,
                color: isDark
                    ? colors.primary
                    : Colors.green.shade600,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildRevenueItem(
            context: context,
            label: "Total Income",
            amount: totalIncome,
            icon: Icons.account_balance_wallet_outlined,
            color: colors.primary,
            isMain: true,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildRevenueItem(
                  context: context,
                  label: "This Month",
                  amount: monthlyIncome,
                  icon: Icons.calendar_month_outlined,
                  color: colors.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueItem(
                  context: context,
                  label: "This Week",
                  amount: weeklyIncome,
                  icon: Icons.calendar_today_outlined,
                  color: colors.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildRevenueItem(
            context: context,
            label: "Today",
            amount: todayIncome,
            icon: Icons.access_time_outlined,
            color: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem({
    required BuildContext context,
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
    bool isMain = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMain ? 16 : 12),
      decoration: BoxDecoration(
        color: isDark
            ? color.withOpacity(0.15)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? color.withOpacity(0.4)
              : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMain ? 10 : 8),
            decoration: BoxDecoration(
              color: isDark
                  ? colors.surface
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: isMain ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: isMain ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? colors.onSurface.withOpacity(0.7)
                            : colors.onSurface.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCurrency(amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: isMain ? 24 : 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: colors.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
