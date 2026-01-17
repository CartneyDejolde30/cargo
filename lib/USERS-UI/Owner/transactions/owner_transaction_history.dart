import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'payout_detail_screen.dart';

class OwnerTransactionHistoryScreen extends StatefulWidget {
  const OwnerTransactionHistoryScreen({super.key});

  @override
  State<OwnerTransactionHistoryScreen> createState() => _OwnerTransactionHistoryScreenState();
}

class _OwnerTransactionHistoryScreenState extends State<OwnerTransactionHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _statistics;
  String? _ownerId;
  String _filterStatus = 'all';

  final String baseUrl = "http://10.139.150.2/carGOAdmin/";

  @override
  void initState() {
    super.initState();
    _loadOwnerIdAndTransactions();
  }

  Future<void> _loadOwnerIdAndTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    _ownerId = prefs.getString('user_id');

    if (_ownerId == null) {
      setState(() => _isLoading = false);
      _showError('Please login to view transactions');
      return;
    }

    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("${baseUrl}api/get_owner_transactions.php?owner_id=$_ownerId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          setState(() {
            _transactions = List<Map<String, dynamic>>.from(result['transactions']);
            _statistics = result['statistics'];
            _isLoading = false;
          });
        } else {
          _showError(result['message'] ?? 'Failed to load transactions');
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

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filterStatus == 'all') return _transactions;
    
    return _transactions.where((t) {
      final escrowStatus = t['escrow_status']?.toString().toLowerCase() ?? '';
      final paymentStatus = t['payment_status']?.toString().toLowerCase() ?? '';
      
      switch (_filterStatus) {
        case 'completed':
          return escrowStatus == 'released';
        case 'escrowed':
          return escrowStatus == 'held';
        case 'paid':
          return t['is_paid'] == true && escrowStatus != 'held';
        case 'pending':
          return paymentStatus == 'pending';
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
      case 'verified':
        return Icons.verified;
      case 'schedule':
        return Icons.schedule;
      case 'sync':
        return Icons.sync;
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
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Earnings & Payouts',
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
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
            'Loading transactions...',
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
          child: _filteredTransactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(_filteredTransactions[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final totalEarnings = double.tryParse(_statistics!['total_earnings']?.toString() ?? '0') ?? 0;
    final pendingPayouts = double.tryParse(_statistics!['pending_payouts']?.toString() ?? '0') ?? 0;
    final platformFees = double.tryParse(_statistics!['platform_fees']?.toString() ?? '0') ?? 0;
    final completedCount = int.tryParse(_statistics!['completed_count']?.toString() ?? '0') ?? 0;
    final escrowedCount = int.tryParse(_statistics!['escrowed_count']?.toString() ?? '0') ?? 0;

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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Overview',
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
                  'Total Earned',
                  _formatCurrency(totalEarnings),
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildStatItem(
                  'In Escrow',
                  _formatCurrency(pendingPayouts),
                  Icons.lock_clock,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountBadge('Completed', completedCount, Colors.green),
                _buildCountBadge('Pending', escrowedCount, Colors.orange),
                _buildCountBadge('Fees Paid', platformFees, Colors.red),
              ],
            ),
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
                color: Colors.white.withOpacity(0.8),
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

  Widget _buildCountBadge(String label, dynamic count, Color color) {
    String displayText = count.toString();
    if (label == 'Fees Paid') {
      final amount = double.tryParse(count.toString()) ?? 0;
      displayText = _formatCurrency(amount);
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            displayText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
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
            _buildFilterChip('completed', 'Completed', Icons.check_circle),
            const SizedBox(width: 8),
            _buildFilterChip('escrowed', 'In Escrow', Icons.lock),
            const SizedBox(width: 8),
            _buildFilterChip('paid', 'Paid', Icons.verified),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending', Icons.schedule),
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

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final statusBadge = transaction['status_badge'] as Map<String, dynamic>? ?? {};
    final bookingId = transaction['booking_id'] ?? 0;
    final ownerPayout = double.tryParse(transaction['owner_payout'].toString()) ?? 0;
    final platformFee = double.tryParse(transaction['platform_fee'].toString()) ?? 0;
    final isCompleted = transaction['is_completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(statusBadge).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PayoutDetailScreen(transaction: transaction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(statusBadge).withOpacity(0.1),
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
                      color: _getStatusColor(statusBadge).withOpacity(0.2),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(ownerPayout),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green.shade700 : Colors.black,
                        ),
                      ),
                      Text(
                        'Your Earnings',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Vehicle Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      transaction['vehicle_image'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: Icon(
                          transaction['vehicle_type'] == 'motorcycle' 
                            ? Icons.two_wheeler 
                            : Icons.directions_car,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['vehicle_name'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rented by: ${transaction['renter_name']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction['booking_date_formatted'] ?? '',
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

            // Fee Breakdown
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Fee (10%)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '-${_formatCurrency(platformFee)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade600,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'all'
                ? 'Your earnings will appear here'
                : 'No ${_filterStatus} transactions',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    ).format(amount);
  }
}