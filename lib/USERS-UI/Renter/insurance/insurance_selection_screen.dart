// Insurance Selection Screen for Renters

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/insurance_models.dart';
import '../../services/insurance_service.dart';
import 'package:cargo/widgets/loading_widgets.dart';

class InsuranceSelectionScreen extends StatefulWidget {
  final int bookingId;
  final int userId;
  final double rentalAmount;
  final Function(String coverageType, double premium) onInsuranceSelected;

  const InsuranceSelectionScreen({
    Key? key,
    required this.bookingId,
    required this.userId,
    required this.rentalAmount,
    required this.onInsuranceSelected,
  }) : super(key: key);

  @override
  State<InsuranceSelectionScreen> createState() => _InsuranceSelectionScreenState();
}

class _InsuranceSelectionScreenState extends State<InsuranceSelectionScreen> {
  List<InsuranceCoverage> _coverages = [];
  bool _isLoading = true;
  String? _selectedCoverageCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoverageTypes();
  }

  Future<void> _loadCoverageTypes() async {
    try {
      final coverages = await InsuranceService.getCoverageTypes();
      setState(() {
        _coverages = coverages;
        _isLoading = false;
        // Auto-select mandatory (basic) coverage
        _selectedCoverageCode = coverages.firstWhere(
          (c) => c.isMandatory,
          orElse: () => coverages.first,
        ).code;
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
        title: Text('Select Insurance Coverage', style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange.shade700,
      ),
      body: _isLoading
          ? const LoadingScreen(message: 'Loading insurance options...')
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
                        onPressed: _loadCoverageTypes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.orange.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ Insurance is Required',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'As per legal requirements, all vehicle rentals must be covered by insurance. Select your preferred coverage level below.',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rental Amount: ${InsuranceService.formatCurrency(widget.rentalAmount)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Coverage Options
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _coverages.length,
                        itemBuilder: (context, index) {
                          final coverage = _coverages[index];
                          final premium = InsuranceService.calculatePremium(
                            rentalAmount: widget.rentalAmount,
                            premiumRate: coverage.premiumRate,
                          );
                          final isSelected = _selectedCoverageCode == coverage.code;

                          return _buildCoverageCard(coverage, premium, isSelected);
                        },
                      ),
                    ),

                    // Confirm Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha :0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedCoverageCode != null ? _confirmSelection : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Confirm Insurance Coverage',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCoverageCard(InsuranceCoverage coverage, double premium, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCoverageCode = coverage.code;
        });
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.orange.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              coverage.name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (coverage.isMandatory) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'REQUIRED',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          coverage.description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.orange.shade700 : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: isSelected ? Colors.orange.shade700 : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Coverage Features
              _buildFeatureRow('🚗 Collision Damage', coverage.features.collisionDamage),
              _buildFeatureRow('👥 Third-Party Liability', coverage.features.thirdPartyLiability),
              if (coverage.features.theftProtection > 0)
                _buildFeatureRow('🔒 Theft Protection', coverage.features.theftProtection),
              if (coverage.features.personalInjury > 0)
                _buildFeatureRow('🏥 Personal Injury', coverage.features.personalInjury),
              if (coverage.features.roadsideAssistance)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.build, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '24/7 Roadside Assistance',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Pricing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deductible:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        InsuranceService.formatCurrency(coverage.features.deductible),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Premium (${coverage.premiumRate.toStringAsFixed(0)}%):',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        InsuranceService.formatCurrency(premium),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          Text(
            'Up to ${InsuranceService.formatCurrency(amount)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedCoverageCode == null) return;

    final selectedCoverage = _coverages.firstWhere(
      (c) => c.code == _selectedCoverageCode,
    );

    final premium = InsuranceService.calculatePremium(
      rentalAmount: widget.rentalAmount,
      premiumRate: selectedCoverage.premiumRate,
    );

    widget.onInsuranceSelected(_selectedCoverageCode!, premium);
    Navigator.pop(context);
  }
}
