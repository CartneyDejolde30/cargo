import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cargo/config/api_config.dart';
import '../../Owner/verification/personal_info_screen.dart';

class VerifyPopup {
  // ✅ Cache verification status to avoid repeated API calls
  static final Map<String, bool> _verificationCache = {};
  static DateTime? _lastCacheUpdate;
  
  /// Main method to show verification popup
  /// Set skipVerificationCheck to true to disable the popup entirely
  static Future<void> showIfNotVerified(
    BuildContext context, {
    bool skipVerificationCheck = false,
  }) async {
    debugPrint("🚀 [VERIFY POPUP] showIfNotVerified() called");
    
    // Skip if verification check is disabled
    if (skipVerificationCheck) {
      debugPrint("⏭️ [VERIFY POPUP] Verification popup disabled for this screen");
      return;
    }

    // Get user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    debugPrint("🔑 [VERIFY POPUP] User ID from SharedPreferences: $userId");

    if (userId == null || userId.isEmpty) {
      debugPrint("❌ [VERIFY POPUP] No user ID found - skipping verification popup");
      return; // Don't show popup if not logged in
    }
    
    debugPrint("✅ [VERIFY POPUP] User ID found: $userId, proceeding with verification check...");

    // ✅ Check cache first (valid for 1 minute only, and ONLY for verified users)
    // We cache verified status to avoid repeated API calls, but NOT unverified status
    // This ensures that newly verified users see the change immediately on next app restart
    if (_verificationCache.containsKey(userId) && 
        _lastCacheUpdate != null && 
        _verificationCache[userId] == true) {
      final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
      debugPrint("📦 [VERIFY POPUP] Verified cache exists for user $userId, age: ${cacheAge.inSeconds} seconds");
      if (cacheAge.inMinutes < 1) {
        debugPrint("✅ [VERIFY POPUP] User is verified (from cache) - popup will NOT show");
        return;
      }
      debugPrint("🔄 [VERIFY POPUP] Cache expired, checking database...");
    } else {
      debugPrint("📭 [VERIFY POPUP] No verified cache found, checking database...");
    }

    // Check verification status from database
    debugPrint("🌐 [VERIFY POPUP] Calling _checkVerificationFromDatabase($userId)...");
    final isVerified = await _checkVerificationFromDatabase(userId);
    
    // ✅ Update cache ONLY if user is verified
    // We don't cache "not verified" status to ensure newly approved users see the change immediately
    if (isVerified) {
      _verificationCache[userId] = true;
      _lastCacheUpdate = DateTime.now();
      debugPrint("💾 [VERIFY POPUP] Cached verified status for user $userId");
    } else {
      // Remove from cache if exists (in case status changed from verified to not verified)
      _verificationCache.remove(userId);
      debugPrint("🗑️ [VERIFY POPUP] Removed cache for user $userId (not verified)");
    }
    
    debugPrint("🔍 [VERIFY POPUP] Verification check result: $isVerified");

    if (isVerified) {
      debugPrint("✅ [VERIFY POPUP] User is verified - popup will NOT show");
      return; // ✅ FIX: User is verified, don't show popup
    }

    debugPrint("⚠️ [VERIFY POPUP] User is NOT verified - showing popup NOW!");
    
    // Check if context is still valid
    if (!context.mounted) {
      debugPrint("❌ [VERIFY POPUP] Context is not mounted, cannot show dialog");
      return;
    }
    
    debugPrint("🎨 [VERIFY POPUP] Context is mounted, creating dialog...");

    try {
      // ✅ Show improved popup if not verified
      debugPrint("🔵 [VERIFY POPUP] About to call showDialog()...");
      await showDialog(
        context: context,
        barrierDismissible: true, // ✅ Allow dismissing by tapping outside
        builder: (dialogContext) {
          debugPrint("🎨 [VERIFY POPUP] Dialog builder called!");
          return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            // ✅ FIX: Use white background instead of theme background
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha :0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Close Button - Improved positioning
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha :0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: Colors.green[700]),
                            const SizedBox(width: 4),
                            Text(
                              '2 mins',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.grey[600], size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// Illustration / Icon Section - Improved design
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha :0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// Title Text - Improved typography
                  Center(
                    child: Text(
                      'Verify Your Identity',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                        // ✅ FIX: Always use dark text on white background
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Subtitle - Improved readability
                  Center(
                    child: Text(
                      'Complete verification to unlock full access and start booking vehicles with CarGO.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// Steps - Improved design with icons
                  _stepWithIcon(
                    icon: Icons.badge_outlined,
                    text: 'Prepare your Driver\'s License or Government ID',
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  _stepWithIcon(
                    icon: Icons.camera_alt_outlined,
                    text: 'Take a clear selfie holding your ID',
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  _stepWithIcon(
                    icon: Icons.description_outlined,
                    text: 'Fill out the verification form',
                    context: context,
                  ),
                  const SizedBox(height: 12),
                  _stepWithIcon(
                    icon: Icons.check_circle_outline,
                    text: 'Wait for CarGO approval (24-48 hours)',
                    context: context,
                  ),

                  const SizedBox(height: 32),

                  /// Buttons - Improved design
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Later',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green[600],
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogContext); // Close popup
                            // ✅ Check mounted before navigation
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PersonalInfoScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Verified Now',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
          );
        },
      );
      debugPrint("✅ [VERIFY POPUP] Dialog shown successfully!");
    } catch (e, stackTrace) {
      debugPrint("❌ [VERIFY POPUP] Error showing dialog: $e");
      debugPrint("❌ [VERIFY POPUP] Stack trace: $stackTrace");
    }
  }

  /// Check verification status from database
  static Future<bool> _checkVerificationFromDatabase(String userId) async {
    try {
      final url = Uri.parse("${GlobalApiConfig.checkVerificationEndpoint}?user_id=$userId");
      debugPrint("📡 [VERIFY POPUP] API URL: $url");
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      debugPrint("📥 [VERIFY POPUP] Response status: ${response.statusCode}");
      debugPrint("📥 [VERIFY POPUP] Response body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final isVerified = result['is_verified'] == true || result['is_verified'] == 1;
        debugPrint("🎯 [VERIFY POPUP] Parsed is_verified: $isVerified");
        debugPrint("🎯 [VERIFY POPUP] Full response: $result");
        return isVerified;
      }
      
      debugPrint("❌ [VERIFY POPUP] Non-200 status code, returning false");
      return false;
    } catch (e) {
      debugPrint("❌ [VERIFY POPUP] Error checking verification: $e");
      debugPrint("❌ [VERIFY POPUP] Stack trace: ${StackTrace.current}");
      return false; // On error, assume not verified (safer)
    }
  }

  /// ✅ New: Step widget with icon
  static Widget _stepWithIcon({
    required IconData icon,
    required String text,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha :0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.green[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                // ✅ FIX: Always use dark text on white background
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  
  /// ✅ New: Clear cache (useful after user completes verification)
  static void clearCache() {
    _verificationCache.clear();
    _lastCacheUpdate = null;
    debugPrint("🗑️ Verification cache cleared");
  }
} 