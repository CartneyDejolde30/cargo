import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/USERS-UI/Owner/models/car_listing.dart';
import 'car_pricing_screen.dart';

class CarRulesScreen extends StatefulWidget {
  final CarListing listing;
   final String vehicleType;

  const CarRulesScreen({super.key, required this.listing,this.vehicleType = 'car',});

  @override
  State<CarRulesScreen> createState() => _CarRulesScreenState();
}

class _CarRulesScreenState extends State<CarRulesScreen> {
  final List<String> availableRules = [
    'Clean As You Go (CLAYGO)',
    'No Littering',
    'No eating or drinking inside',
    'No inter-island travel',
    'No off-roading or driving through flooded areas',
    'No pets allowed',
    'No vaping/smoking',
  ];

  late List<String> selectedRules;
  bool? hasUnlimitedMileage;
  final TextEditingController _dailyLimitController = TextEditingController();
  final TextEditingController _excessRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedRules = List<String>.from(widget.listing.rules);
    hasUnlimitedMileage = widget.listing.hasUnlimitedMileage;
    
    // Initialize with existing values or defaults
    if (widget.listing.mileageLimit != null) {
      _dailyLimitController.text = widget.listing.mileageLimit.toString();
    } else {
      _dailyLimitController.text = widget.vehicleType == 'motorcycle' ? '150' : '200';
    }
    _excessRateController.text = '10'; // Default ₱10/km
  }

  bool _canContinue() {
    return selectedRules.isNotEmpty && hasUnlimitedMileage != null;
  }

void _saveAndContinue() {
  if (_canContinue()) {
    widget.listing.rules = selectedRules;
    widget.listing.hasUnlimitedMileage = hasUnlimitedMileage ?? false;
    
    // Save mileage limit and excess rate
    if (hasUnlimitedMileage == false) {
      final dailyLimit = int.tryParse(_dailyLimitController.text);
      if (dailyLimit == null || dailyLimit <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid daily mileage limit"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      widget.listing.mileageLimit = dailyLimit;
    } else {
      widget.listing.mileageLimit = null; // Unlimited
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarPricingScreen(
          listing: widget.listing,
          vehicleType: widget.vehicleType,
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select rules and mileage option."),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showAddRuleDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Custom Rule', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter a rule'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final newRule = controller.text.trim();
                  availableRules.add(newRule);
                  if (!selectedRules.contains(newRule)) {
                    selectedRules.add(newRule);
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildMileageOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),

            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _excessRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicleType == 'motorcycle' ? 'Your Motorcycle, Your Rules' : 'Your Cars, Your Rules',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black, // Also update color to black
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your own rules',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Rules
                    Text(
                      'What are your car rules?',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),

                    ...availableRules.map(
                      (rule) => CheckboxListTile(
                        value: selectedRules.contains(rule),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedRules.add(rule);
                            } else {
                              selectedRules.remove(rule);
                            }
                          });
                        },
                        title: Text(rule, style: GoogleFonts.poppins(fontSize: 14)),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Theme.of(context).iconTheme.color,

                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _showAddRuleDialog,
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: Text('Add car rule', style: GoogleFonts.poppins(color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Mileage Options
                    Text(
                      'How far can we drive your car?',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMileageOption(
                            'Set mileage limit',
                            hasUnlimitedMileage == false,
                            () => setState(() => hasUnlimitedMileage = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMileageOption(
                            'Unlimited mileage',
                            hasUnlimitedMileage == true,
                            () => setState(() => hasUnlimitedMileage = true),
                          ),
                        ),
                      ],
                    ),

                    // Show mileage limit inputs if "Set mileage limit" is selected
                    if (hasUnlimitedMileage == false) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Mileage Limit Settings',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Daily Limit Input
                            Text(
                              'Daily Mileage Limit (km/day)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _dailyLimitController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: widget.vehicleType == 'motorcycle' ? '150' : '200',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                                prefixIcon: const Icon(Icons.speed, size: 20),
                                suffixText: 'km/day',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Excess Rate Input
                            Text(
                              'Excess Mileage Rate (₱/km)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _excessRateController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '10',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                                prefixIcon: const Icon(Icons.payments, size: 20),
                                suffixText: '₱/km',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Example calculation
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Example (3-day rental):',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Allowed: ${(int.tryParse(_dailyLimitController.text) ?? 200) * 3} km total',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    '• If driven 700 km: ${700 - ((int.tryParse(_dailyLimitController.text) ?? 200) * 3)} km excess',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    '• Excess fee: ₱${(700 - ((int.tryParse(_dailyLimitController.text) ?? 200) * 3)) * (int.tryParse(_excessRateController.text) ?? 10)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue() ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).iconTheme.color,




                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      color: _canContinue() ? Colors.white : (Colors.grey[500] as Color),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
