// Insurance Policy Details Screen

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/insurance_models.dart';
import '../../services/insurance_service.dart';
import 'file_claim_screen.dart';

class InsurancePolicyScreen extends StatefulWidget {
  final int bookingId;
  final int userId;

  const InsurancePolicyScreen({
    Key? key,
    required this.bookingId,
    required this.userId,
  }) : super(key: key);

  @override
  State<InsurancePolicyScreen> createState() => _InsurancePolicyScreenState();
}

class _InsurancePolicyScreenState extends State<InsurancePolicyScreen> {
  InsurancePolicy? _policy;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    try {
      final policy = await InsuranceService.getPolicy(
        userId: widget.userId,
        bookingId: widget.bookingId,
      );
      setState(() {
        _policy = policy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insurance Policy', style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPolicy,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildPolicyDetails(),
    );
  }

  Widget _buildPolicyDetails() {
    if (_policy == null) return const SizedBox();

    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(_policy!.status),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(_policy!.status),
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Policy Status: ${_policy!.status.toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (!_policy!.isExpired && _policy!.status == 'active')
                        Text(
                          '${_policy!.daysRemaining} days remaining',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      if (_policy!.isExpired)
                        Text(
                          'This policy has expired',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Policy Number
                _buildSectionCard(
                  title: 'Policy Information',
                  children: [
                    _buildInfoRow('Policy Number', _policy!.policyNumber),
                    _buildInfoRow('Booking ID', '#${_policy!.bookingId}'),
                    _buildInfoRow('Vehicle Type', _policy!.vehicleType.toUpperCase()),
                    _buildInfoRow('Issued Date', dateTimeFormat.format(_policy!.issuedAt)),
                  ],
                ),

                const SizedBox(height: 16),

                // Coverage Period
                _buildSectionCard(
                  title: 'Coverage Period',
                  children: [
                    _buildInfoRow('Start Date', dateFormat.format(_policy!.policyStart)),
                    _buildInfoRow('End Date', dateFormat.format(_policy!.policyEnd)),
                    _buildInfoRow(
                      'Premium Paid',
                      InsuranceService.formatCurrency(_policy!.premiumAmount),
                      valueColor: Colors.green.shade700,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Coverage Details
                _buildSectionCard(
                  title: 'Coverage Details',
                  subtitle: _policy!.coverage.type.toUpperCase(),
                  children: [
                    _buildInfoRow(
                      'Coverage Limit',
                      InsuranceService.formatCurrency(_policy!.coverage.limit),
                      valueColor: Colors.blue.shade700,
                    ),
                    _buildInfoRow(
                      'Deductible',
                      InsuranceService.formatCurrency(_policy!.coverage.deductible),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Collision Damage',
                      'Up to ${InsuranceService.formatCurrency(_policy!.coverage.collision)}',
                    ),
                    _buildInfoRow(
                      'Third-Party Liability',
                      'Up to ${InsuranceService.formatCurrency(_policy!.coverage.liability)}',
                    ),
                    if (_policy!.coverage.theft > 0)
                      _buildInfoRow(
                        'Theft Protection',
                        'Up to ${InsuranceService.formatCurrency(_policy!.coverage.theft)}',
                      ),
                    if (_policy!.coverage.personalInjury > 0)
                      _buildInfoRow(
                        'Personal Injury',
                        'Up to ${InsuranceService.formatCurrency(_policy!.coverage.personalInjury)}',
                      ),
                    if (_policy!.coverage.roadsideAssistance)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.build_circle, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '24/7 Roadside Assistance Included',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Provider Information
                _buildSectionCard(
                  title: 'Insurance Provider',
                  children: [
                    _buildInfoRow('Provider', _policy!.provider.name),
                    _buildInfoRow('Email', _policy!.provider.email),
                    _buildInfoRow('Phone', _policy!.provider.phone),
                  ],
                ),

                const SizedBox(height: 16),

                // Renter Information
                _buildSectionCard(
                  title: 'Policyholder',
                  children: [
                    _buildInfoRow('Name', _policy!.renter.name),
                    _buildInfoRow('Email', _policy!.renter.email),
                    _buildInfoRow('Contact', _policy!.renter.contact),
                  ],
                ),

                const SizedBox(height: 24),

                // File Claim Button
                if (_policy!.status == 'active')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToFileClaim,
                      icon: const Icon(Icons.report_problem),
                      label: Text(
                        'File Insurance Claim',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Important Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Notice',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This insurance policy is valid only for the duration specified above. In case of an accident or incident, contact your insurance provider immediately and file a claim through the app.',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade600;
      case 'expired':
        return Colors.grey.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'claimed':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'expired':
        return Icons.event_busy;
      case 'cancelled':
        return Icons.cancel;
      case 'claimed':
        return Icons.report_problem;
      default:
        return Icons.info;
    }
  }

  void _navigateToFileClaim() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileClaimScreen(
          policy: _policy!,
          userId: widget.userId,
        ),
      ),
    );

    // Reload policy if claim was filed
    if (result == true) {
      _loadPolicy();
    }
  }
}
