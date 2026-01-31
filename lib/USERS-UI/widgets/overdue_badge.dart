import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable badge widget to display overdue status on booking cards
class OverdueBadge extends StatelessWidget {
  final int daysOverdue;
  final bool isSevere;
  final bool compact;

  const OverdueBadge({
    Key? key,
    required this.daysOverdue,
    this.isSevere = false,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isSevere ? Colors.red[700] : Colors.orange[600],
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        boxShadow: [
          BoxShadow(
            color: (isSevere ? Colors.red : Colors.orange).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSevere ? Icons.warning : Icons.schedule,
            color: Colors.white,
            size: compact ? 14 : 16,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            compact ? 'OVERDUE' : 'OVERDUE: $daysOverdue day${daysOverdue > 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning banner for overdue bookings
class OverdueWarningBanner extends StatelessWidget {
  final int daysOverdue;
  final double lateFee;
  final VoidCallback? onPayNow;

  const OverdueWarningBanner({
    Key? key,
    required this.daysOverdue,
    required this.lateFee,
    this.onPayNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[900]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Overdue',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$daysOverdue day${daysOverdue > 1 ? 's' : ''} past return date',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Late Fee Accumulated',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '₱${lateFee.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onPayNow != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onPayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Pay Now',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '⚠️ Late fees continue to accumulate daily. Please return the vehicle or make payment immediately.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact overdue indicator for list items
class OverdueIndicator extends StatelessWidget {
  final int daysOverdue;
  final double lateFee;

  const OverdueIndicator({
    Key? key,
    required this.daysOverdue,
    required this.lateFee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Overdue: $daysOverdue day${daysOverdue > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[900],
                ),
              ),
              Text(
                'Late Fee: ₱${lateFee.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
