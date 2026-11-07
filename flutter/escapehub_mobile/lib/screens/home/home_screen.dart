import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../widgets/notifications_button.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/room_card.dart';
import '../../widgets/section_header.dart';
import '../room/room_detail_screen.dart';
import 'home_data.dart';
import 'loyalty_summary_card.dart';
import 'promotion_card.dart';
import 'upcoming_booking_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(currentUserProvider.select((user) => user?.firstName ?? ''));
    return Scaffold(
      appBar: AppBar(title: Text('Hello, $firstName'), actions: const [NotificationsButton()]),
      body: ref
          .watch(homeProvider)
          .when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(homeProvider)),
            data: (data) => RefreshIndicator(
              onRefresh: () => ref.refresh(homeProvider.future),
              child: _HomeContent(data: data),
            ),
          ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.data});

  final HomeData data;

  void _openTab(WidgetRef ref, ShellTab tab) => ref.read(shellTabProvider.notifier).select(tab);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: UpcomingBookingCard(booking: data.upcoming, onExplore: () => _openTab(ref, ShellTab.explore)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: LoyaltySummaryCard(balance: data.balance, onOpen: () => _openTab(ref, ShellTab.rewards)),
        ),
        if (data.recommendations.isNotEmpty) ...[
          const SectionHeader('Recommended for you'),
          _RecommendationStrip(items: data.recommendations),
        ],
        SectionHeader('Featured rooms', actionLabel: 'See all', onAction: () => _openTab(ref, ShellTab.explore)),
        _FeaturedStrip(rooms: data.featured),
        if (data.promotions.isNotEmpty) ...[
          const SectionHeader('Active promotions'),
          for (final promotion in data.promotions)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: PromotionCard(promotion: promotion),
            ),
        ],
      ],
    );
  }
}

class _HorizontalStrip extends StatelessWidget {
  const _HorizontalStrip({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class _RecommendationStrip extends StatelessWidget {
  const _RecommendationStrip({required this.items});

  final List<RecommendationDto> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HorizontalStrip(
      height: 232,
      children: [
        for (final item in items)
          RoomTile(
            name: item.name,
            imageUrl: item.imageUrl,
            subtitle: '${item.themeName} -${item.difficultyName}',
            onTap: () => RoomDetailScreen.open(context, item.roomId),
            footer: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.reason,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeaturedStrip extends StatelessWidget {
  const _FeaturedStrip({required this.rooms});

  final List<RoomListItemDto> rooms;

  @override
  Widget build(BuildContext context) {
    return _HorizontalStrip(
      height: 196,
      children: [
        for (final room in rooms)
          RoomTile(
            name: room.name,
            imageUrl: room.imageUrl,
            subtitle: '${room.themeName} -${room.difficultyName}',
            onTap: () => RoomDetailScreen.open(context, room.id),
            footer: RatingSummary(rating: room.averageRating, count: room.reviewCount),
          ),
      ],
    );
  }
}
