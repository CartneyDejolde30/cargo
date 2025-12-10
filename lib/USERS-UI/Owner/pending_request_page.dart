import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PendingRequestsPage extends StatelessWidget {
  final String ownerId; // <-- pass owner ID from login

  const PendingRequestsPage({super.key, required this.ownerId});

  Future<List<dynamic>> fetchPendingRequests() async {
  final url = Uri.parse(
    "http://10.96.221.180/carGOAdmin/api/get_pending_requests.php?owner_id=$ownerId",
  );

  try {
    final response = await http.get(url);

    print("🔥 RAW RESPONSE: ${response.body}");

    if (response.statusCode != 200 || response.body.isEmpty) {
      return [];
    }

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      return data["requests"];
    }

    return [];
  } catch (e) {
    print("❌ ERROR FETCHING: $e");
    return [];
  }
}

void rejectBooking(String bookingId, BuildContext context) {
  TextEditingController reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Reject Booking"),
      content: TextField(
        controller: reasonController,
        decoration: const InputDecoration(
          labelText: "Reason for rejection",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text("Submit"),
          onPressed: () async {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a reason")),
              );
              return;
            }

            Navigator.pop(context); // Close dialog

            final url = Uri.parse(
              "http://10.96.221.180/carGOAdmin/api/reject_request.php",
            );

            final response = await http.post(url, body: {
              "booking_id": bookingId,
              "reason": reasonController.text.trim(),
            });

            final data = jsonDecode(response.body);

            if (data["success"]) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Booking Rejected")),
              );

              // Refresh list
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PendingRequestsPage(ownerId: ownerId)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(data["message"] ?? "Error rejecting booking")),
              );
            }
          },
        ),
      ],
    ),
  );
}


Future<void> approveBooking(String bookingId, BuildContext context) async {
  final url = Uri.parse("http://10.96.221.180/carGOAdmin/api/approve_request.php");

  final response = await http.post(url, body: {
    "booking_id": bookingId,
  });

  final data = jsonDecode(response.body);

  if (data["success"]) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking Approved")),
    );

    // Refresh the screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PendingRequestsPage(ownerId: ownerId)),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"] ?? "Error approving booking")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pending Requests',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      // ---------------- REAL DATA FROM API ----------------
      body: FutureBuilder(
        future: fetchPendingRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
          }

          final requests = snapshot.data as List;

          if (requests.isEmpty) {
            return Center(
              child: Text(
                "No pending requests",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(context, requests[index]);
            },
          );
        },
      ),
    );
  }

  // ---------------- CARD USING REAL DATA ----------------
  Widget _buildRequestCard(BuildContext context, dynamic req) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsPage(request: req),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- CAR IMAGE ----------------
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    req["car_image"] ?? "",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.directions_car, size: 80),
                    ),
                  ),
                ),

                // ---------------- STATUS BADGE ----------------
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCDFE3D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pending Approval',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ---------------- DETAILS SECTION ----------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₱${req["total_amount"]}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '0',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Car name
                  Text(
                    req["car_name"] ?? "Unknown Car",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---------------- LOCATION CHIPS ----------------
                  Row(
                    children: [
                      _buildDetailChip(req["pickup_date"] ?? ""),
                      const SizedBox(width: 8),
                      _buildDetailChip(req["rental_period"]),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---------------- BOOKING DETAILS ----------------
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, 'Renter', req["full_name"]),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.calendar_today, 'Pickup Date', req["pickup_date"]),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.event, 'Return Date', req["return_date"]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---------------- ACTION BUTTONS ----------------
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            rejectBooking(req["booking_id"].toString(), context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reject',
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            approveBooking(req["booking_id"].toString(), context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Approve',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- REUSED UI COMPONENTS ----------------

  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// ---------------- DETAILS PAGE RECEIVING REAL DATA ----------------

class RequestDetailsPage extends StatelessWidget {
  final dynamic request;

  const RequestDetailsPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Details',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              request["car_image"],
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(height: 250, color: Colors.grey[300], child: Icon(Icons.car_crash)),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    request["car_name"],
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  _buildSection("Renter Information", [
                    _buildDetailRow("Name", request["full_name"]),
                    _buildDetailRow("Contact", request["contact"]),
                    _buildDetailRow("Email", request["email"]),
                  ]),

                  const SizedBox(height: 20),

                  _buildSection("Booking Details", [
                    _buildDetailRow("Pickup Date", request["pickup_date"]),
                    _buildDetailRow("Return Date", request["return_date"]),
                    _buildDetailRow("Period", request["rental_period"]),
                    _buildDetailRow("Total Amount", "₱${request["total_amount"]}"),
                  ]),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reject',
                            style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Approve',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          Text(value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        ],
      ),
    );
  }
}
