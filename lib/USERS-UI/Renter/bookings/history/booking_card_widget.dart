import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingCardWidget extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String status;

  const BookingCardWidget({
    super.key,
    required this.booking,
    required this.status,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'active':
        return Colors.black;
      case 'pending':
        return Colors.grey.shade700;
      case 'upcoming':
        return Colors.grey.shade600;
      case 'past':
        return Colors.grey.shade500;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending Payment';
      case 'upcoming':
        return 'Confirmed';
      case 'past':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Car image and basic info
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car image
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(booking['carImage']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Car details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking['carName'],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'active' 
                                  ? Colors.black 
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: status != 'active'
                                  ? Border.all(color: Colors.grey.shade300)
                                  : null,
                            ),
                            child: Text(
                              _getStatusText(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: status == 'active'
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking['location'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Booking ID: ${booking['bookingId']}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.shade200),

          // Rental period
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    'Pick up',
                    booking['pickupDate'],
                    booking['pickupTime'],
                  ),
                ),
                Container(
                  width: 40,
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ),
                Expanded(
                  child: _buildDateInfo(
                    'Return',
                    booking['returnDate'],
                    booking['returnTime'],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.shade200),

          // Price and action button
          Padding(
            padding: EdgeInsets.all(16),
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
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '₱${booking['totalPrice']}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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

  Widget _buildDateInfo(String label, String date, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          date,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 12,
              color: Colors.grey.shade500,
            ),
            SizedBox(width: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (status) {
      case 'active':
        return ElevatedButton(
          onPressed: () {
            print('View active booking');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            'View Details',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'pending':
        return ElevatedButton(
          onPressed: () {
            print('Complete payment');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            'Pay Now',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'upcoming':
        return OutlinedButton(
          onPressed: () {
            print('View upcoming booking');
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.black),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'View Details',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'past':
        return OutlinedButton(
          onPressed: () {
            print('Book again');
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Book Again',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }
}