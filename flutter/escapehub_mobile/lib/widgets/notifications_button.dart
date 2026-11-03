import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/notifications/notifications_screen.dart';

class NotificationsButton extends ConsumerWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => const NotificationsScreen())),
      icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
    );
  }
}
