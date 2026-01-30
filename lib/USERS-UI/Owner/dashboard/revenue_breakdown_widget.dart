import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Revenue Breakdown Widget
/// Displays detailed revenue information with gross, fees, refunds, and net amounts
class RevenueBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic>? revenueBreakdown;
  final String period; // 'total', 'monthly', 'weekly', 'today'

  const RevenueBreakdownWidget({
    Key? key,
    required this.revenueBreakdown,
    this.period = 'total',
  }) : super(key: key);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (revenueBreakdown == null || !revenueBreakdown!.containsKey(period)) {
      return const SizedBox.shrink();
    }

    final data = revenueBreakdown![period] as Map<String, dynamic>;
    final grossRevenue = double.tryParse(data['gross_revenue']?.toString() ?? '0') ?? 0.0;
    final lateFees = double.tryParse(data['late_fees']?.toString() ?? '0') ?? 0.0;
    final refundsIssued = double.tryParse(data['refunds_issued']?.toString() ?? '0') ?? 0.0;
    final netRevenue = double.tryParse(data['net_revenue']?.toString() ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _getPeriodLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(netRevenue > 0 ? 'Active' : 'No Activity'),
            ],
          ),
          const SizedBox(height: 20),

          // Gross Revenue
          _buildRevenueRow(
            label: 'Gross Revenue',
            amount: grossRevenue,
            icon: Icons.trending_up,
            color: Colors.blue,
            isPositive: true,
          ),
          
          // Late Fees (if any)
          if (lateFees > 0) ...[
            const SizedBox(height: 12),
            _buildRevenueRow(
              label: 'Late Fees',
              amount: lateFees,
              icon: Icons.schedule,
              color: Colors.orange,
              isPositive: true,
              isSubItem: true,
            ),
          ],
          
          // Refunds (if any)
          if (refundsIssued > 0) ...[
            const SizedBox(height: 12),
            _buildRevenueRow(
              label: 'Refunds Issued',
              amount: refundsIssued,
              icon: Icons.replay,
              color: Colors.red,
              isPositive: false,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade200,
                  Colors.purple.shade200,
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Net Revenue
          _buildRevenueRow(
            label: 'Net Revenue',
            amount: netRevenue,
            icon: Icons.account_balance,
            color: Colors.green,
            isPositive: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueRow({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isPositive,
    bool isTotal = false,
    bool isSubItem = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isTotal ? 16 : 12),
      decoration: BoxDecoration(
        color: isTotal ? Colors.white : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTotal ? color.withOpacity(0.3) : Colors.transparent,
          width: isTotal ? 2 : 0,
        ),
        boxShadow: isTotal
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isTotal ? 24 : 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isSubItem ? Colors.grey.shade700 : Colors.black87,
              ),
            ),
          ),
          
          // Amount
          Text(
            '${isPositive ? '' : '-'}${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isPositive ? color : Colors.red.shade700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (period) {
      case 'total':
        return 'All Time';
      case 'monthly':
        return 'This Month';
      case 'weekly':
        return 'This Week';
      case 'today':
        return 'Today';
      default:
        return period;
    }
  }
}

/// Expandable Revenue Breakdown Card
/// Shows all time periods in an expandable format
class ExpandableRevenueBreakdown extends StatefulWidget {
  final Map<String, dynamic>? revenueBreakdown;

  const ExpandableRevenueBreakdown({
    Key? key,
    required this.revenueBreakdown,
  }) : super(key: key);

  @override
  State<ExpandableRevenueBreakdown> createState() =>
      _ExpandableRevenueBreakdownState();
}

class _ExpandableRevenueBreakdownState
    extends State<ExpandableRevenueBreakdown> {
  String _selectedPeriod = 'total';

  @override
  Widget build(BuildContext context) {
    if (widget.revenueBreakdown == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Period Selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _buildPeriodChip('total', 'All Time', Icons.calendar_month),
              const SizedBox(width: 8),
              _buildPeriodChip('monthly', 'Month', Icons.calendar_today),
              const SizedBox(width: 8),
              _buildPeriodChip('weekly', 'Week', Icons.date_range),
              const SizedBox(width: 8),
              _buildPeriodChip('today', 'Today', Icons.today),
            ],
          ),
        ),

        // Breakdown Widget
        RevenueBreakdownWidget(
          revenueBreakdown: widget.revenueBreakdown,
          period: _selectedPeriod,
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String period, String label, IconData icon) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade600 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Revenue Summary Card
/// Shows a quick summary without detailed breakdown
class CompactRevenueSummary extends StatelessWidget {
  final Map<String, dynamic>? revenueBreakdown;
  final VoidCallback? onTapDetails;

  const CompactRevenueSummary({
    Key? key,
    required this.revenueBreakdown,
    this.onTapDetails,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (revenueBreakdown == null || !revenueBreakdown!.containsKey('total')) {
      return const SizedBox.shrink();
    }

    final data = revenueBreakdown!['total'] as Map<String, dynamic>;
    final grossRevenue = double.tryParse(data['gross_revenue']?.toString() ?? '0') ?? 0.0;
    final refundsIssued = double.tryParse(data['refunds_issued']?.toString() ?? '0') ?? 0.0;
    final netRevenue = double.tryParse(data['net_revenue']?.toString() ?? '0') ?? 0.0;

    return GestureDetector(
      onTap: onTapDetails,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Summary',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(netRevenue),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (refundsIssued > 0)
                    Text(
                      '${_formatCurrency(grossRevenue)} - ${_formatCurrency(refundsIssued)} refunds',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            if (onTapDetails != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
