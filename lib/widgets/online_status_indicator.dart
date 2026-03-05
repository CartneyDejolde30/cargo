import 'package:flutter/material.dart';
import 'package:cargo/services/user_presence_service.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget to display user's online status with "Active Now" indicator
class OnlineStatusIndicator extends StatelessWidget {
  final String userId;
  final bool showText;
  final double size;
  final Color? onlineColor;
  final Color? offlineColor;

  const OnlineStatusIndicator({
    super.key,
    required this.userId,
    this.showText = true,
    this.size = 12,
    this.onlineColor,
    this.offlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final presenceService = UserPresenceService();

    return StreamBuilder<bool>(
      stream: presenceService.getUserPresenceStream(userId),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;

        if (!showText) {
          // Just show the indicator dot
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isOnline 
                  ? (onlineColor ?? Colors.green) 
                  : (offlineColor ?? Colors.grey),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: size * 0.15,
              ),
            ),
          );
        }

        // Show text with indicator
        if (isOnline) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: onlineColor ?? Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: size * 0.5),
              Text(
                'Active Now',
                style: TextStyle(
                  color: onlineColor ?? Colors.green,
                  fontSize: size * 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        } else {
          // Show last seen
          return StreamBuilder<DateTime?>(
            stream: presenceService.getUserLastSeenStream(userId),
            builder: (context, lastSeenSnapshot) {
              final lastSeen = lastSeenSnapshot.data;
              
              if (lastSeen == null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: offlineColor ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: size * 0.5),
                    Text(
                      'Offline',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: size * 1.1,
                      ),
                    ),
                  ],
                );
              }

              final lastSeenText = timeago.format(lastSeen, locale: 'en_short');
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: offlineColor ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: size * 0.5),
                  Text(
                    'Last seen $lastSeenText',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: size * 1.1,
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
}

/// Simple online status badge (just a colored dot)
class OnlineStatusBadge extends StatelessWidget {
  final String userId;
  final double size;
  final Color? onlineColor;
  final Color? offlineColor;
  final bool showBorder;

  const OnlineStatusBadge({
    super.key,
    required this.userId,
    this.size = 12,
    this.onlineColor,
    this.offlineColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final presenceService = UserPresenceService();

    return StreamBuilder<bool>(
      stream: presenceService.getUserPresenceStream(userId),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isOnline 
                ? (onlineColor ?? Colors.green) 
                : (offlineColor ?? Colors.grey.shade400),
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(
                    color: Colors.white,
                    width: size * 0.2,
                  )
                : null,
          ),
        );
      },
    );
  }
}
