import 'dart:async';

import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formatting.dart';
import '../../widgets/paged_list_view.dart';
import 'notification_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _readIds = <int>{};
  late final Timer _timer;
  int _tick = 0;
  int _reloads = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(UnreadNotificationsNotifier.interval, (_) => setState(() => _tick++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _open(NotificationDto notification) async {
    if (notification.isRead || _readIds.contains(notification.id)) return;
    setState(() => _readIds.add(notification.id));
    try {
      await ref.read(unreadNotificationsProvider.notifier).markRead(notification.id);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _readIds.remove(notification.id));
      showErrorSnackBar(context, error);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(unreadNotificationsProvider.notifier).markAllRead();
      if (!mounted) return;
      setState(() => _reloads++);
      showSuccessSnackBar(context, 'All notifications were marked as read.');
    } on ApiException catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiClientProvider);
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Tooltip(
            message: unread == 0
                ? 'All notifications are already read.'
                : 'Mark ${plural(unread, 'notification')} as read.',
            child: TextButton.icon(
              onPressed: unread == 0 ? null : _markAllRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all read'),
            ),
          ),
        ],
      ),
      body: PagedListView<NotificationDto>(
        reloadKey: _reloads,
        refreshKey: (unread, _tick),
        itemKey: (notification) => notification.id,
        fetch: (page) => api.notifications.list(page: page),
        emptyIcon: Icons.notifications_none,
        emptyMessage: 'You have no notifications. Booking updates and rewards show here.',
        spacing: 0,
        itemBuilder: (context, notification) => NotificationTile(
          notification: notification,
          isRead: notification.isRead || _readIds.contains(notification.id),
          onTap: () => _open(notification),
        ),
      ),
    );
  }
}
