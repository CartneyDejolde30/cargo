import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cargo/config/api_config.dart';

class RenterDamageReportScreen extends StatefulWidget {
  final int bookingId;
  final String renterId;
  final String vehicleName;

  const RenterDamageReportScreen({
    super.key,
    required this.bookingId,
    required this.renterId,
    required this.vehicleName,
  });

  @override
  State<RenterDamageReportScreen> createState() => _RenterDamageReportScreenState();
}

class _RenterDamageReportScreenState extends State<RenterDamageReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
        '${GlobalApiConfig.getRenterDamageReportEndpoint}?booking_id=${widget.bookingId}&renter_id=${widget.renterId}',
      );
      final response = await http.get(uri).timeout(GlobalApiConfig.apiTimeout);
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _report = data['report'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load report. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  List<String> _parseTypes(dynamic raw) {
    if (raw == null) return [];
    try {
      if (raw is List) return List<String>.from(raw);
      final decoded = json.decode(raw.toString());
      if (decoded is List) return List<String>.from(decoded);
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Damage Report', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReport,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _report == null
                  ? _buildNoReport()
                  : _buildReport(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoReport() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade400),
            const SizedBox(height: 20),
            Text(
              'No Damage Report',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The vehicle owner has not filed any damage report for this booking.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    final report = _report!;
    final status = report['status']?.toString() ?? 'pending';
    final types = _parseTypes(report['damage_types']);
    final ownerName = report['owner_name'] ?? 'Vehicle Owner';
    final estimatedCost = double.tryParse(report['estimated_cost']?.toString() ?? '0') ?? 0.0;
    final approvedAmount = double.tryParse(report['approved_amount']?.toString() ?? '0') ?? 0.0;
    final adminNotes = report['admin_notes']?.toString() ?? '';
    final createdAt = report['created_at']?.toString() ?? '';

    final images = [
      report['image_1'], report['image_2'], report['image_3'], report['image_4']
    ].where((e) => e != null && e.toString().isNotEmpty).toList();

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    String statusDesc;
    switch (status) {
      case 'approved':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.warning_rounded;
        statusLabel = 'Damage Approved';
        statusDesc = '₱${approvedAmount.toStringAsFixed(2)} will be deducted from your security deposit.';
        break;
      case 'rejected':
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle;
        statusLabel = 'Report Dismissed';
        statusDesc = 'Admin reviewed the report and found insufficient evidence. No deduction will be made.';
        break;
      default:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.hourglass_top;
        statusLabel = 'Under Review';
        statusDesc = 'Admin is reviewing the damage report. You will be notified of the outcome.';
    }

    return RefreshIndicator(
      onRefresh: _fetchReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        statusLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusDesc,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filed by / date
            _buildInfoRow('Filed By', ownerName),
            const SizedBox(height: 12),
            _buildInfoRow('Booking', '#BK-${widget.bookingId.toString().padLeft(4, '0')} — ${widget.vehicleName}'),
            const SizedBox(height: 12),
            _buildInfoRow('Filed On', _formatDate(createdAt)),
            const SizedBox(height: 20),

            // Damage types
            Text('Reported Damage Types', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(t, style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade800)),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Description
            Text('Description', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                report['description'] ?? '',
                style: GoogleFonts.inter(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // Cost breakdown
            Text('Cost Details', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildCostRow('Estimated Cost', '₱${estimatedCost.toStringAsFixed(2)}', Colors.grey.shade800),
                  if (status == 'approved') ...[
                    const Divider(height: 20),
                    _buildCostRow(
                      'Approved Deduction',
                      '₱${approvedAmount.toStringAsFixed(2)}',
                      Colors.red.shade700,
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),

            if (adminNotes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Admin Notes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  adminNotes,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.blue.shade900, height: 1.5),
                ),
              ),
            ],

            if (images.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Evidence Photos', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _showFullImage(GlobalApiConfig.getImageUrl(images[i].toString())),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      GlobalApiConfig.getImageUrl(images[i].toString()),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If you believe this report is inaccurate, please contact support or file a dispute through the app.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: valueColor,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
