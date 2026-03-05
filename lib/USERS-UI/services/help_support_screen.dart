import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cargo/USERS-UI/services/faqs_screen.dart';
import 'package:cargo/USERS-UI/services/privacy_policy_screen.dart';
import 'package:cargo/config/app_info.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Quick help'),
          _tile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'FAQs',
            subtitle: 'Common questions and answers',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQsScreen())),
          ),
          _tile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read how we handle your data',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          const SizedBox(height: 18),

          _sectionTitle('Contact support'),
          _tile(
            context,
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: AppInfo.supportEmail,
            onTap: () => _launch(Uri.parse('mailto:${AppInfo.supportEmail}?subject=${Uri.encodeComponent('Cargo Support')}')),
          ),
          _tile(
            context,
            icon: Icons.phone_outlined,
            title: 'Call',
            subtitle: AppInfo.supportPhone,
            onTap: () => _launch(Uri.parse('tel:${AppInfo.supportPhone}')),
          ),
          _tile(
            context,
            icon: Icons.facebook,
            title: 'Facebook',
            subtitle: 'Message us on Facebook',
            onTap: () => _launch(Uri.parse(AppInfo.supportFacebookUrl)),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
            ),
            child: Text(
              'If you encounter booking/payment issues, please include your booking ID when contacting support.',
              style: GoogleFonts.poppins(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.75)),
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }
}
