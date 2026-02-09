import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/online_status_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

/// Example widget showing how to use OnlineStatusIndicator in different contexts
class UserOnlineStatusWidget extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const UserOnlineStatusWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with online badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: userAvatar != null && userAvatar!.startsWith('http')
                      ? NetworkImage(userAvatar!)
                      : null,
                  child: userAvatar == null || !userAvatar!.startsWith('http')
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: OnlineStatusBadge(
                    userId: userId,
                    size: 14,
                    showBorder: true,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // User info with online status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  OnlineStatusIndicator(
                    userId: userId,
                    showText: true,
                    size: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
