import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../bookings/my_bookings_screen.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _visited = <ShellTab>{};

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      selectedIcon: Icon(Icons.event_note),
      label: 'Bookings',
    ),
    NavigationDestination(
      icon: Icon(Icons.card_giftcard_outlined),
      selectedIcon: Icon(Icons.card_giftcard),
      label: 'Rewards',
    ),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ];

  Widget _screen(ShellTab tab) {
    if (!_visited.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      ShellTab.home => const HomeScreen(),
      ShellTab.explore => const ExploreScreen(),
      ShellTab.bookings => const MyBookingsScreen(),
      ShellTab.rewards => const RewardsScreen(),
      ShellTab.profile => const ProfileScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(shellTabProvider);
    _visited.add(current);
    ref.listen(unreadNotificationsProvider.select((count) => count.value), (previous, next) {
      if (previous != null && next != null && next > previous) ref.bookingsChanged();
    });
    return Scaffold(
      body: IndexedStack(index: current.index, children: [for (final tab in ShellTab.values) _screen(tab)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current.index,
        onDestinationSelected: (index) => ref.read(shellTabProvider.notifier).select(ShellTab.values[index]),
        destinations: _destinations,
      ),
    );
  }
}
