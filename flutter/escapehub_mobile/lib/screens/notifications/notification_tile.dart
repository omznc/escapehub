import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.isRead, required this.onTap});

  final NotificationDto notification;
  final bool isRead;
  final VoidCallback onTap;

  static const _icons = {
    NotificationType.bookingCreated: Icons.event_note_outlined,
    NotificationType.bookingConfirmed: Icons.event_available_outlined,
    NotificationType.bookingCancelled: Icons.event_busy_outlined,
    NotificationType.bookingRejected: Icons.event_busy_outlined,
    NotificationType.bookingNoShow: Icons.person_off_outlined,
    NotificationType.sessionReminder: Icons.alarm,
    NotificationType.bookingCompleted: Icons.emoji_events_outlined,
    NotificationType.resultRecorded: Icons.emoji_events_outlined,
    NotificationType.loyaltyPointsAwarded: Icons.loyalty_outlined,
    NotificationType.rewardRedeemed: Icons.card_giftcard_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRead ? null : theme.colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(_icons[notification.type]!, color: theme.colorScheme.primary),
        title: Text(notification.title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(formatTimestamp(notification.createdAt), style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: isRead
            ? null
            : Tooltip(
                message: 'Not read',
                child: Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
              ),
      ),
    );
  }
}
