import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Owner/verification/personal_info_screen.dart';

class VerifyPopup {
  static Future<void> showIfNotVerified(BuildContext context) async {
    final box = GetStorage();
    final bool isVerified = box.read('isVerified') ?? false;

    if (isVerified) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                /// Close Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),

                const SizedBox(height: 20),

                /// Illustration / Icon Section
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.green[300],
                        child: const Icon(Icons.emoji_emotions, size: 80, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Just takes 2 mins!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// Title Text
                Text(
                  'Hi there!\nLet\'s get you\nverified first.',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// Subtitle
                Text(
                  'Get verified so you can book freely anytime, anywhere with Cargo.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 24),

                /// Steps
                _stepText('1. Prepare your Driver\'s License or any Government ID.'),
                _stepText('2. Take a selfie holding your ID.'),
                _stepText('3. Fill out the Verification Information Sheet.'),
                _stepText('4. Wait for Cargo Approval.'),

                const SizedBox(height: 30),

                /// Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext); // Close popup
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInfoScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Get Verified',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable step text widget
  static Widget _stepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
