import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/USERS-UI/Renter/payments/refund_request_screen.dart';
import 'booking_detail_screen.dart';
import 'package:flutter_application_1/USERS-UI/Reporting/submit_review_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/models/booking.dart';
import 'package:flutter_application_1/USERS-UI/models/overdue_booking.dart';
import 'package:flutter_application_1/USERS-UI/services/overdue_service.dart';
import 'package:flutter_application_1/USERS-UI/widgets/overdue_badge.dart';
import 'package:flutter_application_1/USERS-UI/Renter/payments/late_fee_payment_screen.dart';

class BookingCardWidget extends StatefulWidget {
  final Booking booking;
  final String status;
  final VoidCallback? onReviewSubmitted;

  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.status,
    this.onReviewSubmitted,
  });

  @override
  State<BookingCardWidget> createState() => _BookingCardWidgetState();
}

class _BookingCardWidgetState extends State<BookingCardWidget> {
  final OverdueService _overdueService = OverdueService();
  OverdueBooking? _overdueInfo;
  bool _isCheckingOverdue = false;

  @override
  void initState() {
    super.initState();
    // Check for overdue status if booking is active
    if (widget.status.toLowerCase() == 'active' || 
        widget.booking.status.toLowerCase() == 'approved') {
      _checkOverdueStatus();
    }
  }

  Future<void> _checkOverdueStatus() async {
    if (_isCheckingOverdue) return;
    
    setState(() => _isCheckingOverdue = true);
    
    try {
      final overdueInfo = await _overdueService.checkBookingOverdue(widget.booking.bookingId);
      if (mounted) {
        setState(() {
          _overdueInfo = overdueInfo;
          _isCheckingOverdue = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking overdue status: $e');
      if (mounted) {
        setState(() => _isCheckingOverdue = false);
      }
    }
  }

  String _getStatusText() {
    switch (widget.booking.status.toLowerCase()) {
      case 'approved':
        return 'Active';
      case 'pending':
        return 'Pending Payment';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return widget.booking.status;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
     decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: Theme.of(context).colorScheme.outlineVariant,
  ),
  boxShadow: [
    BoxShadow(
      color: Theme.of(context).shadowColor.withOpacity(0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ],
),

      child: Column(
        children: [
          // =========================
          // OVERDUE BADGE (if applicable)
          // =========================
          if (_overdueInfo != null && _overdueInfo!.hasLateFee)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: OverdueWarningBanner(
                daysOverdue: _overdueInfo!.daysOverdue,
                lateFee: _overdueInfo!.lateFeeAmount,
                onPayNow: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LateFeePaymentScreen(
                        bookingId: widget.booking.bookingId,
                        rentalAmount: _overdueInfo!.totalAmount,
                        lateFee: _overdueInfo!.lateFeeAmount,
                        hoursOverdue: _overdueInfo!.hoursOverdue,
                        vehicleName: _overdueInfo!.vehicleName,
                        isRentalPaid: _overdueInfo!.isRentalPaid,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      // Refresh overdue status after payment
                      _checkOverdueStatus();
                      if (widget.onReviewSubmitted != null) {
                        widget.onReviewSubmitted!();
                      }
                    }
                  });
                },
              ),
            ),
          
          // =========================
          // CAR INFO
          // =========================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,

                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildCarImage(widget.booking.carImage),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.booking.carName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).iconTheme.color,



                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _statusBadge(context),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                                Icons.location_on,
                                size: 14,
                                color: Theme.of(context).colorScheme.outline,
                              ),

                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.booking.location,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Booking ID: ${widget.booking.bookingId}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      // Show refund badge if applicable
                      if (widget.booking.refundStatus != null && 
                          widget.booking.refundStatus != 'not_requested') ...[
                        const SizedBox(height: 6),
                        _buildRefundBadge(context),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),


          // =========================
          // RENTAL PERIOD
          // =========================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    context,
                    'Pick up',
                    widget.booking.pickupDate,
                    widget.booking.pickupTime,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Theme.of(context).colorScheme.outline,
                    ),

                ),
                Expanded(
                  child: _buildDateInfo(
                    context,
                    'Return',
                    widget.booking.returnDate,
                    widget.booking.returnTime,
                  ),
                ),
              ],
            ),
          ),

         Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),


          // =========================
          // PRICE + ACTION
          // =========================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${widget.booking.totalPrice}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).iconTheme.color,



                      ),
                    ),
                  ],
                ),
                _buildActionButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // STATUS BADGE
  // =========================
Widget _statusBadge(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  Color bg;
  Color fg;

  switch (widget.booking.status.toLowerCase()) {
    case 'approved':
      bg = scheme.primary;
      fg = scheme.onPrimary;
      break;
    case 'pending':
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
      break;
    case 'completed':
      bg = Colors.green.shade700;
      fg = Colors.white;
      break;
    case 'cancelled':
      bg = Colors.orange.shade700;
      fg = Colors.white;
      break;
    case 'rejected':
      bg = Colors.red.shade700;
      fg = Colors.white;
      break;
    default:
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      _getStatusText(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    ),
  );
}

  // =========================
  // REFUND BADGE
  // =========================
  Widget _buildRefundBadge(BuildContext context) {
    final refundStatus = widget.booking.refundStatus?.toLowerCase() ?? '';
    
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;
    
    switch (refundStatus) {
      case 'requested':
      case 'pending':
        badgeColor = Colors.orange.shade100;
        badgeIcon = Icons.schedule;
        badgeText = 'Refund Pending';
        break;
      case 'approved':
        badgeColor = Colors.blue.shade100;
        badgeIcon = Icons.check_circle_outline;
        badgeText = 'Refund Approved';
        break;
      case 'processing':
        badgeColor = Colors.purple.shade100;
        badgeIcon = Icons.sync;
        badgeText = 'Processing Refund';
        break;
      case 'completed':
        badgeColor = Colors.green.shade100;
        badgeIcon = Icons.check_circle;
        badgeText = 'Refunded';
        break;
      case 'rejected':
        badgeColor = Colors.red.shade100;
        badgeIcon = Icons.cancel;
        badgeText = 'Refund Rejected';
        break;
      default:
        badgeColor = Colors.grey.shade100;
        badgeIcon = Icons.info;
        badgeText = 'Refund Status';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 12,
            color: badgeColor.computeLuminance() > 0.5 
                ? Colors.grey.shade800 
                : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor.computeLuminance() > 0.5 
                  ? Colors.grey.shade800 
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // ACTION BUTTON
  // =========================
// Update the _buildActionButton method in booking_card_widget.dart

Widget _buildActionButton(BuildContext context) {
  // 🔥 Always prioritize refund for rejected/cancelled
  if (widget.booking.status.toLowerCase() == 'rejected' ||
      widget.booking.status.toLowerCase() == 'cancelled') {
    return _buildRefundButton(context);
  }

  switch (widget.status) {
    case 'active':
    case 'upcoming':
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                booking: widget.booking,
                status: widget.status,
              ),
            ),
          ).then((result) {
            if (result == true && widget.onReviewSubmitted != null) {
              widget.onReviewSubmitted!();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.status == 'upcoming' ? Colors.white : Colors.black,
          foregroundColor: widget.status == 'upcoming' ? Colors.black : Colors.white,
          side: widget.status == 'upcoming'
              ? const BorderSide(color: Colors.black)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          'View Details',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

    case 'pending':
      // ✅ Changed from "Pay Now" to "View Details"
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                booking: widget.booking,
                status: widget.status,
              ),
            ),
          ).then((result) {
            if (result == true && widget.onReviewSubmitted != null) {
              widget.onReviewSubmitted!();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          'View Details',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      );

    case 'completed':
      // ✅ Rate & Review button for completed bookings
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubmitReviewScreen(
                bookingId: widget.booking.bookingId.toString(),
                carId: widget.booking.carId.toString(),
                carName: widget.booking.carName,
                carImage: widget.booking.carImage,
                ownerId: widget.booking.ownerId.toString(),
                ownerName: widget.booking.ownerName,
                ownerImage: '',
              ),
            ),
          ).then((result) {
            if (result == true && widget.onReviewSubmitted != null) { widget.onReviewSubmitted!();
            }
          });
        },
        style: ElevatedButton.styleFrom(
           backgroundColor: Theme.of(context).iconTheme.color,




          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Rate & Review',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.surface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

    case 'past':
      // Keep for backward compatibility
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubmitReviewScreen(
                bookingId: widget.booking.bookingId.toString(),
                carId: widget.booking.carId.toString(),
                carName: widget.booking.carName,
                carImage: widget.booking.carImage,
                ownerId: widget.booking.ownerId.toString(),
                ownerName: widget.booking.ownerName,
                ownerImage: '',
              ),
            ),
          ).then((result) {
            if (result == true && widget.onReviewSubmitted != null) { widget.onReviewSubmitted!();
            }
          });
        },
        style: ElevatedButton.styleFrom(
           backgroundColor: Theme.of(context).iconTheme.color,




          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Rate & Review',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.surface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

    default:
      return const SizedBox.shrink();
  }
}


// 🆕 ADD THIS NEW METHOD
Widget _buildRefundButton(BuildContext context) {
  return ElevatedButton(
    onPressed: () async {
      // Navigate to refund request screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RefundRequestScreen(
            bookingId: widget.booking.bookingId,
            bookingReference: '#BK-${widget.booking.bookingId.toString().padLeft(4, '0')}',
            totalAmount: double.tryParse(widget.booking.totalPrice.replaceAll(',', '')) ?? 0,
            cancellationDate: DateTime.now().toString(),
            paymentMethod: 'gcash', // Get from booking data if available
            paymentReference: widget.booking.bookingId.toString(),
          ),
        ),
      );

      if (result == true && widget.onReviewSubmitted != null) { widget.onReviewSubmitted!(); // Refresh bookings
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.undo, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          'Request Refund',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

  // =========================
  // HELPERS
  // =========================
  Widget _buildCarImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.cover);
    }
    return Image.asset(imagePath, fit: BoxFit.cover);
  }

  Widget _buildDateInfo(BuildContext context,String label, String date, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(date,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Row(
          children: [
           Icon(
              Icons.access_time,
              size: 12,
              color: Theme.of(context).colorScheme.outline,
            ),

            const SizedBox(width: 4),
            Text(time,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline
)),
          ],
        ),
      ],
    );
  }
}
