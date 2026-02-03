import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/USERS-UI/Renter/payments/refund_request_screen.dart';
import 'booking_detail_screen.dart';
import 'package:flutter_application_1/USERS-UI/Reporting/submit_review_screen.dart';
import 'package:flutter_application_1/USERS-UI/Renter/models/booking.dart';

class BookingCardWidget extends StatelessWidget {
  final Booking booking;
  final String status;
  final VoidCallback? onReviewSubmitted;

  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.status,
    this.onReviewSubmitted,
  });

  String _getStatusText() {
  switch (booking.status.toLowerCase()) {
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
      return booking.status;
  }
}


  @override
  Widget build(BuildContext context) {
    return Container(
     decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceVariant,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.transparent   // no white border in dark mode
      : Colors.grey.shade300, // soft border in light mode
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
                    color: Theme.of(context).colorScheme.surfaceVariant,

                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildCarImage(booking.carImage),
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
                              booking.carName,
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
                              booking.location,
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
                        'Booking ID: ${booking.bookingId}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline,

                        ),
                      ),
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
                    booking.pickupDate,
                    booking.pickupTime,
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
                    booking.returnDate,
                    booking.returnTime,
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
                      '₱${booking.totalPrice}',
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

  switch (booking.status.toLowerCase()) {
    case 'approved':
      bg = scheme.primary;
      fg = scheme.onPrimary;
      break;
    case 'pending':
      bg = scheme.surfaceVariant;
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
      bg = scheme.surfaceVariant;
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
  // ACTION BUTTON
  // =========================
// Update the _buildActionButton method in booking_card_widget.dart

Widget _buildActionButton(BuildContext context) {
  // 🔥 Always prioritize refund for rejected/cancelled
  if (booking.status.toLowerCase() == 'rejected' ||
      booking.status.toLowerCase() == 'cancelled') {
    return _buildRefundButton(context);
  }

  switch (status) {
    case 'active':
    case 'upcoming':
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                booking: booking,
                status: status,
              ),
            ),
          ).then((result) {
            if (result == true && onReviewSubmitted != null) {
              onReviewSubmitted!();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: status == 'upcoming' ? Colors.white : Colors.black,
          foregroundColor: status == 'upcoming' ? Colors.black : Colors.white,
          side: status == 'upcoming'
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
                booking: booking,
                status: status,
              ),
            ),
          ).then((result) {
            if (result == true && onReviewSubmitted != null) {
              onReviewSubmitted!();
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
                bookingId: booking.bookingId.toString(),
                carId: booking.carId.toString(),
                carName: booking.carName,
                carImage: booking.carImage,
                ownerId: booking.ownerId.toString(),
                ownerName: booking.ownerName,
                ownerImage: '',
              ),
            ),
          ).then((result) {
            if (result == true && onReviewSubmitted != null) {
              onReviewSubmitted!();
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
                bookingId: booking.bookingId.toString(),
                carId: booking.carId.toString(),
                carName: booking.carName,
                carImage: booking.carImage,
                ownerId: booking.ownerId.toString(),
                ownerName: booking.ownerName,
                ownerImage: '',
              ),
            ),
          ).then((result) {
            if (result == true && onReviewSubmitted != null) {
              onReviewSubmitted!();
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
            bookingId: booking.bookingId,
            bookingReference: '#BK-${booking.bookingId.toString().padLeft(4, '0')}',
            totalAmount: double.tryParse(booking.totalPrice.replaceAll(',', '')) ?? 0,
            cancellationDate: DateTime.now().toString(),
            paymentMethod: 'gcash', // Get from booking data if available
            paymentReference: booking.bookingId.toString(),
          ),
        ),
      );

      if (result == true && onReviewSubmitted != null) {
        onReviewSubmitted!(); // Refresh bookings
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
