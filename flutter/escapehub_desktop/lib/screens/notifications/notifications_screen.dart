import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/actions.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';

const _icons = {
  NotificationType.bookingCreated: Icons.event_note_outlined,
  NotificationType.bookingConfirmed: Icons.check_circle_outline,
  NotificationType.bookingCancelled: Icons.event_busy_outlined,
  NotificationType.bookingRejected: Icons.block,
  NotificationType.bookingCompleted: Icons.task_alt,
  NotificationType.bookingNoShow: Icons.person_off_outlined,
  NotificationType.sessionReminder: Icons.alarm,
  NotificationType.resultRecorded: Icons.emoji_events_outlined,
  NotificationType.loyaltyPointsAwarded: Icons.loyalty_outlined,
  NotificationType.rewardRedeemed: Icons.redeem_outlined,
  NotificationType.paymentReceived: Icons.payments_outlined,
  NotificationType.paymentRefunded: Icons.currency_exchange,
};

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  var _unreadOnly = false;
  var _page = 1;
  late Future<Paged<NotificationDto>> _future = _load();

  Future<Paged<NotificationDto>> _load() =>
      ref.read(apiClientProvider).notifications.list(unreadOnly: _unreadOnly, page: _page);

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  Future<void> _markRead(NotificationDto notification) async {
    final notifier = ref.read(unreadNotificationsProvider.notifier);
    await runAction(context, () => notifier.markRead(notification.id), 'The notification was marked as read.');
  }

  Future<void> _markAllRead() async {
    final notifier = ref.read(unreadNotificationsProvider.notifier);
    await runAction(context, notifier.markAllRead, 'All notifications were marked as read.');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(unreadNotificationsProvider, (previous, next) {
      if (previous?.value != next.value) _reload(page: _page);
    });
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    return ListPage(
      filters: [
        FilterChip(
          label: const Text('Unread only'),
          selected: _unreadOnly,
          onSelected: (value) {
            _unreadOnly = value;
            _reload();
          },
        ),
        Text(unread == 1 ? '1 unread notification' : '$unread unread notifications'),
      ],
      actions: [
        Tooltip(
          message: unread == 0 ? 'All notifications are read.' : 'Mark all notifications as read',
          child: OutlinedButton.icon(
            onPressed: unread == 0 ? null : _markAllRead,
            icon: const Icon(Icons.done_all),
            label: const Text('Mark all as read'),
          ),
        ),
      ],
      child: FutureView<Paged<NotificationDto>>(
        future: _future,
        onRetry: () => _reload(page: _page),
        builder: (context, page) => Column(
          children: [
            Expanded(
              child: page.items.isEmpty
                  ? const EmptyMessage('There are no notifications.', icon: Icons.notifications_none)
                  : ListView.separated(
                      itemCount: page.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => _NotificationTile(
                        notification: page.items[index],
                        onMarkRead: () => _markRead(page.items[index]),
                      ),
                    ),
            ),
            const Divider(height: 1),
            Pager(
              page: page,
              onPage: (value) => _reload(page: value),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onMarkRead});

  final NotificationDto notification;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      tileColor: unread ? theme.colorScheme.surfaceContainerLow : null,
      leading: Icon(_icons[notification.type], color: theme.colorScheme.onSurfaceVariant),
      title: Text(notification.title, style: TextStyle(fontWeight: unread ? FontWeight.w600 : FontWeight.normal)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 4),
          Text(formatTimestamp(notification.createdAt), style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: unread
          ? TextButton(onPressed: onMarkRead, child: const Text('Mark as read'))
          : Text('Read', style: theme.textTheme.bodySmall),
    );
  }
}
