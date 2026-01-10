import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'receipt_viewer_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _refunds = [];
  List<Map<String, dynamic>> _escrow = [];

  final String baseUrl = "http://192.168.1.11/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('${baseUrl}api/get_user_payment_history.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _allTransactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
            _payments = List<Map<String, dynamic>>.from(data['payments'] ?? []);
            _refunds = List<Map<String, dynamic>>.from(data['refunds'] ?? []);
            _escrow = List<Map<String, dynamic>>.from(data['escrow'] ?? []);
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load payment history');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading payment history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    ).format(value);
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'verified':
      case 'completed':
      case 'released':
        return Colors.green.shade600;
      case 'pending':
      case 'processing':
        return Colors.orange.shade600;
      case 'failed':
      case 'rejected':
      case 'cancelled':
        return Colors.red.shade600;
      case 'held':
      case 'escrow_held':
        return Colors.blue.shade600;
      case 'refunded':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'verified':
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
      case 'rejected':
        return Icons.cancel;
      case 'held':
      case 'escrow_held':
        return Icons.lock_clock;
      case 'refunded':
        return Icons.undo;
      case 'released':
        return Icons.check_circle_outline;
      default:
        return Icons.info;
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment History',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'All (${_allTransactions.length})'),
            Tab(text: 'Payments (${_payments.length})'),
            Tab(text: 'Escrow (${_escrow.length})'),
            Tab(text: 'Refunds (${_refunds.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : RefreshIndicator(
              onRefresh: _loadPaymentHistory,
              color: Colors.black,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionList(_allTransactions, 'all'),
                  _buildTransactionList(_payments, 'payment'),
                  _buildTransactionList(_escrow, 'escrow'),
                  _buildTransactionList(_refunds, 'refund'),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions, String type) {
    if (transactions.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'payment':
        message = 'No payment transactions yet';
        icon = Icons.payment;
        break;
      case 'escrow':
        message = 'No escrow transactions';
        icon = Icons.account_balance;
        break;
      case 'refund':
        message = 'No refunds issued';
        icon = Icons.undo;
        break;
      default:
        message = 'No transactions found';
        icon = Icons.receipt_long;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final status = transaction['status'] ?? transaction['payment_status'] ?? 'pending';
    final transactionType = transaction['transaction_type'] ?? 'payment';
    final amount = transaction['amount'] ?? transaction['total_amount'] ?? '0';
    final bookingId = transaction['booking_id']?.toString() ?? 'N/A';
    final date = transaction['created_at'] ?? transaction['verified_at'] ?? '';
    final paymentMethod = transaction['payment_method'] ?? 'N/A';
    final reference = transaction['payment_reference'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionDetails(transaction),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTransactionTypeLabel(transactionType),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
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
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatStatus(status),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatCurrency(amount),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: transactionType == 'refund'
                            ? Colors.green.shade700
                            : Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Payment Method
                if (paymentMethod != 'N/A')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Method',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          paymentMethod.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Reference Number
                if (reference.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reference',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          reference,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                // View Receipt Button (if available)
                if (status.toLowerCase() == 'verified' ||
                    status.toLowerCase() == 'completed')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptViewerScreen(
                                bookingId: int.tryParse(bookingId) ?? 0,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: Text(
                          'View Receipt',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTransactionTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return 'Payment';
      case 'escrow_hold':
        return 'Escrow Hold';
      case 'escrow_release':
        return 'Escrow Release';
      case 'refund':
        return 'Refund';
      case 'payout':
        return 'Payout';
      default:
        return type;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...transaction.entries.map((entry) {
              if (entry.value == null || entry.value.toString().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatKey(entry.key),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        entry.value.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}