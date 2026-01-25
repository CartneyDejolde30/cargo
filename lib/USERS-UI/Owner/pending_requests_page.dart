// lib/USERS-UI/Owner/pending_requests_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'req_model/pending_request_card.dart';
import 'req_model/request_dialog.dart';
import 'req_model/booking_request.dart';
import 'req_model/request_details_page.dart';
import 'mycar/api_config.dart';

class PendingRequestsPage extends StatefulWidget {
  final String ownerId;

  const PendingRequestsPage({super.key, required this.ownerId});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  List<BookingRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse(
      "${ApiConfig.pendingRequestsEndpoint}?owner_id=${widget.ownerId}",
    );

    try {
      debugPrint("📡 Fetching pending requests: $url");
      
      final response = await http.get(url).timeout(ApiConfig.apiTimeout);
      
      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📥 Response body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() {
            _requests = [];
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        }

        final data = jsonDecode(response.body);
        
        if (data["success"] == true) {
          final requestsList = (data["requests"] as List)
              .map((req) => BookingRequest.fromJson(req))
              .toList();
          
          setState(() {
            _requests = requestsList;
            _isLoading = false;
            _errorMessage = null;
          });
          
          debugPrint("✅ Loaded ${_requests.length} pending requests");
        } else {
          setState(() {
            _requests = [];
            _isLoading = false;
            _errorMessage = data["message"] ?? "Failed to load requests";
          });
          debugPrint("⚠️ API returned error: ${data["message"]}");
        }
      } else {
        setState(() {
          _requests = [];
          _isLoading = false;
          _errorMessage = "Server error: ${response.statusCode}";
        });
        debugPrint("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _requests = [];
        _isLoading = false;
        _errorMessage = "Network error. Please check your connection.";
      });
      debugPrint("❌ ERROR FETCHING: $e");
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchPendingRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).iconTheme.color,



                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
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
                  color: Theme.of(context).iconTheme.color,



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
                  color: Theme.of(context).iconTheme.color,



                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _fetchPendingRequests,
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),

          // Content
          SliverFillRemaining(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: _buildEmptyState(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Theme.of(context).iconTheme.color,



      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return PendingRequestCard(
            request: request,
            ownerId: widget.ownerId,
            onApprove: () => _handleApprove(request),
            onReject: () => _handleReject(request),
            onTap: () => _navigateToDetails(request),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).iconTheme.color,



            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              "Oops!",
              style: GoogleFonts.outfit(
                fontSize: 24,
                color: Theme.of(context).iconTheme.color,



                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPendingRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                 backgroundColor: Theme.of(context).iconTheme.color,




                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          const SizedBox(height: 8),
          Text(
            "New booking requests will appear here",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BookingRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailsPage(
          request: request,
          ownerId: widget.ownerId,
        ),
      ),
    ).then((_) => _fetchPendingRequests());
  }

  void _handleReject(BookingRequest request) {
    // Just call the dialog - it handles everything internally including refresh
    RequestDialogs.showRejectDialog(
      context,
      request.bookingId,
      widget.ownerId,
      onSuccess: _fetchPendingRequests,
    );
  }

  void _handleApprove(BookingRequest request) {
    _showApprovalFlow(request);
  }

  Future<void> _showApprovalFlow(BookingRequest request) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Booking?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to approve this booking:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.carName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renter: ${request.fullName}',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  Text(
                    'Amount: ₱${request.totalAmount}',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.black),
                const SizedBox(height: 16),
                Text('Approving booking...', style: GoogleFonts.inter()),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final url = Uri.parse(ApiConfig.approveBookingEndpoint);
      final response = await http.post(url, body: {
        "booking_id": request.bookingId,
        "owner_id": widget.ownerId,
      }).timeout(ApiConfig.apiTimeout);

      if (!mounted) return;

      Navigator.pop(context); // Remove loading

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data["message"] ?? "Booking approved successfully",
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        _fetchPendingRequests();
      } else {
        if (!mounted) return;
        
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
      if (!mounted) return;
      
      Navigator.pop(context);
      
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