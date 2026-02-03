import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'receipt_viewer_screen.dart';
import 'refund_request_screen.dart';
import 'refund_history_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic>? _statistics;
  String? _userId;
  String _filterStatus = 'all';

  final String baseUrl = "http://10.77.127.2/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    _loadUserIdAndPayments();
  }

  Future<void> _loadUserIdAndPayments() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');

    if (_userId == null) {
      setState(() => _isLoading = false);
      _showError('Please login to view payment history');
      return;
    }

    await _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("${baseUrl}api/get_user_payment_history.php?user_id=$_userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          setState(() {
            _payments = List<Map<String, dynamic>>.from(result['payments']);
            _statistics = result['statistics'];
            _isLoading = false;
          });
        } else {
          _showError(result['message'] ?? 'Failed to load payments');
          setState(() => _isLoading = false);
        }
      } else {
        _showError('Server error: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Network error: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPayments {
    if (_filterStatus == 'all') return _payments;
    
    return _payments.where((p) {
      final paymentStatus = p['payment_status']?.toString().toLowerCase() ?? '';
      final escrowStatus = p['escrow_status']?.toString().toLowerCase() ?? '';
      
      switch (_filterStatus) {
        case 'verified':
          return paymentStatus == 'verified' || escrowStatus == 'held';
        case 'pending':
          return paymentStatus == 'pending';
        case 'completed':
          return escrowStatus == 'released_to_owner';
        case 'rejected':
          return paymentStatus == 'rejected' || paymentStatus == 'failed';
        case 'refunded':
          return escrowStatus == 'refunded';
        default:
          return true;
      }
    }).toList();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getStatusColor(Map<String, dynamic> statusBadge) {
    switch (statusBadge['color']?.toString().toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(Map<String, dynamic> statusBadge) {
    switch (statusBadge['icon']?.toString()) {
      case 'check_circle':
        return Icons.check_circle;
      case 'lock':
        return Icons.lock;
      case 'schedule':
        return Icons.schedule;
      case 'cancel':
        return Icons.cancel;
      case 'undo':
        return Icons.undo;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Payment History',
        style: GoogleFonts.poppins(
          color: Theme.of(context).iconTheme.color,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        // View Refunds Button
        IconButton(
          icon: Icon(
            Icons.receipt_long_outlined,
            color: Theme.of(context).iconTheme.color,
          ),
          tooltip: 'View Refunds',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RefundHistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.black),
          const SizedBox(height: 16),
          Text(
            'Loading payments...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (_statistics != null) _buildStatisticsCard(),
        _buildFilterChips(),
        Expanded(
          child: _filteredPayments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchPaymentHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredPayments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(_filteredPayments[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final totalPaid = double.tryParse(_statistics!['total_paid']?.toString() ?? '0') ?? 0;
    final totalPending = double.tryParse(_statistics!['total_pending']?.toString() ?? '0') ?? 0;
    final verifiedCount = int.tryParse(_statistics!['verified_count']?.toString() ?? '0') ?? 0;
    final pendingCount = int.tryParse(_statistics!['pending_count']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Overview',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Paid',
                  _formatCurrency(totalPaid),
                  Icons.payments,
                  Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildStatItem(
                  'Pending',
                  _formatCurrency(totalPending),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCountBadge('Verified', verifiedCount, Colors.green),
              _buildCountBadge('Pending', pendingCount, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All', Icons.list),
            const SizedBox(width: 8),
            _buildFilterChip('verified', 'Paid', Icons.check_circle),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending', Icons.schedule),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Completed', Icons.done_all),
            const SizedBox(width: 8),
            _buildFilterChip('rejected', 'Failed', Icons.cancel),
            const SizedBox(width: 8),
            _buildFilterChip('refunded', 'Refunded', Icons.undo),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final statusBadge = payment['status_badge'] as Map<String, dynamic>? ?? {};
    final bookingId = payment['booking_id'] ?? 0;
    final amount = double.tryParse(payment['amount'].toString()) ?? 0;
    final hasReceipt = payment['has_receipt'] == true || payment['has_receipt'] == 1;
    final canRefund = payment['can_request_refund'] == true || payment['can_request_refund'] == 1;
    
    // Check if refund was requested or processed
    final refundStatus = payment['refund_status']?.toString();
    final hasRefund = refundStatus != null && refundStatus != 'not_requested';
    final refundAmount = payment['refund_amount'] != null 
        ? double.tryParse(payment['refund_amount'].toString()) ?? 0 
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(statusBadge).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(statusBadge).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusBadge).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(statusBadge),
                    color: _getStatusColor(statusBadge),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusBadge['label']?.toString() ?? 'UNKNOWN',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(statusBadge),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Booking #$bookingId',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(amount),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).iconTheme.color,



                  ),
                ),
              ],
            ),
          ),

          // Car Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    payment['car_image'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.directions_car, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['car_full_name'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment['payment_date_formatted'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      // Show refund status if exists
                      if (hasRefund) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getRefundIcon(refundStatus),
                              size: 12,
                              color: _getRefundColor(refundStatus),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getRefundLabel(refundStatus),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getRefundColor(refundStatus),
                              ),
                            ),
                            if (refundStatus == 'completed' && refundAmount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '• ${_formatCurrency(refundAmount.toDouble())}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.shade200),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (hasReceipt)
                  Expanded(
                    child: _buildActionButton(
                      'View Receipt',
                      Icons.receipt_long,
                      Colors.black,
                      () => _viewReceipt(bookingId),
                    ),
                  ),
                if (hasReceipt && (canRefund || hasRefund)) const SizedBox(width: 8),
                if (hasRefund)
                  // Show "View Refund" if refund already exists
                  Expanded(
                    child: _buildActionButton(
                      'View Refund',
                      Icons.info_outline,
                      Colors.blue.shade600,
                      () => _viewRefundHistory(),
                    ),
                  )
                else if (canRefund)
                  // Show "Request Refund" only if no refund exists
                  Expanded(
                    child: _buildActionButton(
                      'Request Refund',
                      Icons.undo,
                      Colors.red.shade600,
                      () => _requestRefund(payment),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No payments found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'all'
                ? 'Your payment history will appear here'
                : 'No ${_filterStatus} payments',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _viewReceipt(int bookingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptViewerScreen(bookingId: bookingId),
      ),
    );
  }

  void _requestRefund(Map<String, dynamic> payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RefundRequestScreen(
          bookingId: payment['booking_id'],
          bookingReference: '#BK-${payment['booking_id']}',
          totalAmount: double.tryParse(payment['amount'].toString()) ?? 0,
          cancellationDate: payment['payment_date'] ?? DateTime.now().toString(),
          paymentMethod: payment['payment_method'] ?? 'N/A',
          paymentReference: payment['payment_reference'] ?? 'N/A',
        ),
      ),
    ).then((result) {
      if (result == true) {
        _fetchPaymentHistory();
      }
    });
  }

  void _viewRefundHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RefundHistoryScreen(),
      ),
    );
  }

  // Helper methods for refund status display
  IconData _getRefundIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'requested':
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getRefundColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'requested':
      case 'pending':
        return Colors.orange.shade600;
      case 'approved':
        return Colors.blue.shade600;
      case 'processing':
        return Colors.purple.shade600;
      case 'completed':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getRefundLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'requested':
        return 'Refund Requested';
      case 'pending':
        return 'Refund Pending';
      case 'approved':
        return 'Refund Approved';
      case 'processing':
        return 'Refund Processing';
      case 'completed':
        return 'Refunded';
      case 'rejected':
        return 'Refund Rejected';
      default:
        return 'Refund Status';
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    ).format(amount);
  }
}