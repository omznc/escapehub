import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../bookings/bookings_screen.dart';
import '../clients/clients_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../notifications/notifications_screen.dart';
import '../promotions/promotions_screen.dart';
import '../reference/reference_screen.dart';
import '../reports/reports_screen.dart';
import '../reviews/reviews_screen.dart';
import '../rooms/rooms_screen.dart';
import '../scenarios/scenarios_screen.dart';
import '../schedules/schedules_screen.dart';
import '../settings/settings_screen.dart';
import '../users/users_screen.dart';
import 'change_password_dialog.dart';
import 'section.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _visit = 0;

  static const _pages = <Section, Widget>{
    Section.dashboard: DashboardScreen(),
    Section.notifications: NotificationsScreen(),
    Section.bookings: BookingsScreen(),
    Section.schedules: SchedulesScreen(),
    Section.rooms: RoomsScreen(),
    Section.scenarios: ScenariosScreen(),
    Section.promotions: PromotionsScreen(),
    Section.clients: ClientsScreen(),
    Section.reviews: ReviewsScreen(),
    Section.loyalty: LoyaltyScreen(),
    Section.reports: ReportsScreen(),
    Section.users: UsersScreen(),
    Section.referenceData: ReferenceScreen(),
    Section.settings: SettingsScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final section = ref.watch(sectionProvider);
    ref.listen(sectionProvider, (previous, next) => _visit++);
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: section.label),
                Expanded(
                  child: Navigator(
                    key: ValueKey((section, _visit)),
                    onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _pages[section]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(sectionProvider);
    final isAdministrator = ref.watch(currentUserProvider.select((user) => user?.isAdministrator ?? false));
    final sections = Section.visibleFor(isAdministrator: isAdministrator);
    return Container(
      width: 240,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(Icons.lock_person_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('EscapeHub', style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final group in SectionGroup.values)
                  if (sections.any((section) => section.group == group)) ...[
                    _GroupLabel(group.label),
                    for (final section in sections.where((section) => section.group == group))
                      _SidebarItem(
                        section: section,
                        selected: section == selected,
                        onTap: () => ref.read(sectionProvider.notifier).open(section),
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(text, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.section, required this.selected, required this.onTap});

  final Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      selected: selected,
      selectedColor: colors.onSecondaryContainer,
      selectedTileColor: colors.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(section.icon),
      title: Text(section.label),
      onTap: onTap,
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const Spacer(),
          const _NotificationBell(),
          const SizedBox(width: 12),
          const _UserMenu(),
        ],
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    return IconButton(
      tooltip: unread == 0 ? 'Notifications' : 'Notifications: $unread unread',
      onPressed: () => ref.read(sectionProvider.notifier).open(Section.notifications),
      icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
    );
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu();

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(sessionProvider.notifier).logout();
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('You are signed out on this computer, but the server did not confirm it: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.password),
          onPressed: () => showDialog<void>(context: context, builder: (_) => const ChangePasswordDialog()),
          child: const Text('Change password'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout),
          onPressed: () => _logout(context, ref),
          child: const Text('Sign out'),
        ),
      ],
      builder: (context, controller, _) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              ApiImage(
                path: user.profilePictureUrl,
                label: user.fullName,
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: theme.textTheme.titleSmall),
                  Text(roleLabel(user.role), style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }
}
