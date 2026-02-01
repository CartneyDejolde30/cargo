import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Owner Protection Widget
/// Shows escrow protection status and payment guarantees for overdue bookings
class OwnerProtectionWidget extends StatelessWidget {
  final double rentalAmount;
  final double lateFee;
  final int daysOverdue;
  final String escrowStatus;
  final bool lateFeeCharged;
  final String paymentStatus;

  const OwnerProtectionWidget({
    Key? key,
    required this.rentalAmount,
    required this.lateFee,
    required this.daysOverdue,
    required this.escrowStatus,
    required this.lateFeeCharged,
    required this.paymentStatus,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    ).format(amount);
  }

  Color _getStatusColor() {
    if (escrowStatus == 'held' || escrowStatus == 'held_overdue') {
      return Colors.green;
    } else if (escrowStatus == 'released_to_owner') {
      return Colors.blue;
    }
    return Colors.orange;
  }

  IconData _getStatusIcon() {
    if (escrowStatus == 'held' || escrowStatus == 'held_overdue') {
      return Icons.shield_outlined;
    } else if (escrowStatus == 'released_to_owner') {
      return Icons.check_circle_outline;
    }
    return Icons.info_outline;
  }

  String _getProtectionMessage() {
    if (escrowStatus == 'held' || escrowStatus == 'held_overdue') {
      return 'Your payment is protected in escrow';
    } else if (escrowStatus == 'released_to_owner') {
      return 'Payment released to you';
    }
    return 'Payment processing';
  }

  @override
  Widget build(BuildContext context) {
    final totalOwed = rentalAmount + lateFee;
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Protection',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        _getProtectionMessage(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (escrowStatus == 'held' || escrowStatus == 'held_overdue')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PROTECTED',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Payment Breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Rental Amount (In Escrow)
                _buildAmountRow(
                  label: 'Rental Amount',
                  amount: rentalAmount,
                  subtitle: escrowStatus == 'held' || escrowStatus == 'held_overdue'
                      ? 'Secured in escrow ✓'
                      : 'Released',
                  isProtected: escrowStatus == 'held' || escrowStatus == 'held_overdue',
                ),
                const SizedBox(height: 12),

                // Late Fee (if applicable)
                if (daysOverdue > 0) ...[
                  _buildAmountRow(
                    label: 'Late Fees Owed',
                    amount: lateFee,
                    subtitle: lateFeeCharged
                        ? 'Paid by renter ✓'
                        : paymentStatus == 'pending'
                            ? 'Payment pending verification'
                            : 'Awaiting payment',
                    isProtected: lateFeeCharged,
                    isWarning: !lateFeeCharged,
                  ),
                  const SizedBox(height: 12),
                ],

                // Divider
                const Divider(),
                const SizedBox(height: 12),

                // Total Owed
                _buildAmountRow(
                  label: 'Total You\'re Owed',
                  amount: totalOwed,
                  isTotal: true,
                ),
              ],
            ),
          ),

          // Status Message
          if (daysOverdue > 0 && !lateFeeCharged)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your rental payment (${_formatCurrency(rentalAmount)}) is secure. '
                      'Late fees will be added once renter pays.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountRow({
    required String label,
    required double amount,
    String? subtitle,
    bool isProtected = false,
    bool isWarning = false,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? Colors.black : Colors.grey[700],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isProtected)
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.green[700],
                      ),
                    if (isWarning)
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.orange[700],
                      ),
                    if (isProtected || isWarning) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isProtected
                              ? Colors.green[700]
                              : isWarning
                                  ? Colors.orange[700]
                                  : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Compact version for list items
class OwnerProtectionBadge extends StatelessWidget {
  final String escrowStatus;
  final bool isOverdue;

  const OwnerProtectionBadge({
    Key? key,
    required this.escrowStatus,
    required this.isOverdue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (escrowStatus != 'held' && escrowStatus != 'held_overdue') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            color: Colors.green[700],
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Protected',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}
