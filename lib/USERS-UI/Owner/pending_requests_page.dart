import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'req_model/pending_request_card.dart';
import 'req_model/request_dialog.dart';
import 'req_model/booking_request.dart';
import 'req_model/request_details_page.dart';

class PendingRequestsPage extends StatelessWidget {
  final String ownerId;

  const PendingRequestsPage({super.key, required this.ownerId});

  // Temporary mock data for UI preview
  List<BookingRequest> _getMockData() {
    return [
      BookingRequest(
        bookingId: '1',
        carName: 'Toyota Vios 2024',
        carImage: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=800',
        totalAmount: '4200',
        pickupDate: 'Dec 25, 2025',
        returnDate: 'Dec 28, 2025',
        rentalPeriod: '3 days',
        fullName: 'John Doe',
        contact: '+63 912 345 6789',
        email: 'johndoe@email.com',
        location: 'Tampakan, South Cotabato',
        seats: '5-seater',
        transmission: 'Automatic',
      ),
      BookingRequest(
        bookingId: '2',
        carName: 'Honda City 2024',
        carImage: 'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=800',
        totalAmount: '3500',
        pickupDate: 'Dec 22, 2025',
        returnDate: 'Dec 24, 2025',
        rentalPeriod: '2 days',
        fullName: 'Maria Santos',
        contact: '+63 923 456 7890',
        email: 'maria.santos@email.com',
        location: 'Midsayap, Cotabato',
        seats: '5-seater',
        transmission: 'Manual',
      ),
      BookingRequest(
        bookingId: '3',
        carName: 'Mitsubishi Mirage 2023',
        carImage: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
        totalAmount: '2800',
        pickupDate: 'Dec 21, 2025',
        returnDate: 'Dec 23, 2025',
        rentalPeriod: '2 days',
        fullName: 'Pedro Cruz',
        contact: '+63 945 678 9012',
        email: 'pedro.cruz@email.com',
        location: 'Koronadal City',
        seats: '4-seater',
        transmission: 'Manual',
      ),
    ];
  }

  Future<List<BookingRequest>> fetchPendingRequests() async {
    // Uncomment this for real API calls
    /*
    final url = Uri.parse(
      "http://192.168.1.11/carGOAdmin/api/get_pending_requests.php?owner_id=$ownerId",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200 || response.body.isEmpty) {
        return _getMockData(); // Fallback to mock data
      }

      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return (data["requests"] as List)
            .map((req) => BookingRequest.fromJson(req))
            .toList();
      }
      return _getMockData();
    } catch (e) {
      print("❌ ERROR FETCHING: $e");
      return _getMockData();
    }
    */

    // For now, return mock data after a delay to simulate loading
    await Future.delayed(const Duration(seconds: 1));
    return _getMockData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Pending Requests',
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // Bookings List
          SliverToBoxAdapter(
            child: FutureBuilder<List<BookingRequest>>(
              future: fetchPendingRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 400,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    height: 400,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No pending requests",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final requests = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      ...requests.map((request) => PendingRequestCard(
                            request: request,
                            ownerId: ownerId,
                            onApprove: () => _handleApprove(request, context),
                            onReject: () => _handleReject(request, context),
                            onTap: () => _navigateToDetails(request, context),
                          )),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BookingRequest request, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailsPage(
          request: request,
          ownerId: ownerId,
        ),
      ),
    );
  }

  void _handleReject(BookingRequest request, BuildContext context) {
    RequestDialogs.showRejectDialog(
      context,
      request.bookingId,
      ownerId,
    );
  }

  void _handleApprove(BookingRequest request, BuildContext context) async {
    final url =
        Uri.parse("http://192.168.1.11/carGOAdmin/api/approve_request.php");

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final response = await http.post(url, body: {
        "booking_id": request.bookingId,
      });

      Navigator.pop(context); // Remove loading

      final data = jsonDecode(response.body);

      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Booking Approved",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => PendingRequestsPage(ownerId: ownerId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Error approving booking",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading if error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Network error occurred",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}