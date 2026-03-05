import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
            ),
            child: Text(
              'This Privacy Policy explains how Cargo collects, uses, and protects your information when you use the app.\n\n'
              'We may collect account details, booking information, and device/network data to provide services like authentication, bookings, payments, and safety features.\n\n'
              'We do not sell your personal data. We only share data when required to provide the service (for example, booking details between owner and renter) or when required by law.\n\n'
              'For questions or data requests, contact support through Help & Support.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: colors.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
