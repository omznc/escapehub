import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/charts.dart';
import '../../widgets/pages.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/status_chip.dart';
import '../bookings/booking_detail_screen.dart';
import '../shell/section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late Future<DashboardStatsDto> _stats = _load();

  Future<DashboardStatsDto> _load() => ref.read(apiClientProvider).dashboard.stats();

  void _reload() => setState(() => _stats = _load());

  Future<void> _openBooking(int bookingId) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(bookingId: bookingId)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureView<DashboardStatsDto>(
        future: _stats,
        onRetry: _reload,
        builder: (context, stats) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _QuickLinks(onRefresh: _reload),
            const SizedBox(height: 16),
            _Cards(stats: stats),
            const SizedBox(height: 16),
            _TwoColumns(
              left: SectionCard(
                title: 'Bookings by day',
                child: SimpleLineChart(
                  points: [
                    for (final day in stats.bookingsByDay)
                      ChartPoint(formatDate(day.date).substring(5), day.count.toDouble()),
                  ],
                  format: (value) => '${value.toInt()} bookings',
                ),
              ),
              right: SectionCard(
                title: 'Revenue by room',
                child: SimpleBarChart(
                  points: [for (final room in stats.revenueByRoom) ChartPoint(room.roomName, room.value)],
                  format: formatMoney,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TwoColumns(
              left: SectionCard(
                title: 'Occupancy by room',
                child: SimpleBarChart(
                  points: [for (final room in stats.occupancyByRoom) ChartPoint(room.roomName, room.value)],
                  format: formatPercent,
                ),
              ),
              right: SectionCard(
                title: 'Top clients by bookings',
                child: SimpleBarChart(
                  points: [
                    for (final client in stats.topClients) ChartPoint(client.clientName, client.bookings.toDouble()),
                  ],
                  format: (value) => '${value.toInt()} bookings',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TwoColumns(
              left: SectionCard(
                title: 'Upcoming sessions',
                child: _UpcomingSessions(sessions: stats.upcomingSessions, onOpen: _openBooking),
              ),
              right: SectionCard(
                title: 'Latest reviews',
                child: _LatestReviews(reviews: stats.latestReviews),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinks extends ConsumerWidget {
  const _QuickLinks({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    void open(Section section) => ref.read(sectionProvider.notifier).open(section);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Welcome, ${user?.firstName ?? ''}. Today is ${formatDate(today())}.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final section in const [Section.bookings, Section.schedules, Section.rooms, Section.reports])
              OutlinedButton.icon(onPressed: () => open(section), icon: Icon(section.icon), label: Text(section.label)),
            IconButton(tooltip: 'Refresh the dashboard', onPressed: onRefresh, icon: const Icon(Icons.refresh)),
          ],
        ),
      ],
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.stats});

  final DashboardStatsDto stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        StatTile(icon: Icons.today_outlined, label: 'Bookings today', value: '${stats.todayBookings}'),
        StatTile(icon: Icons.date_range_outlined, label: 'Bookings this week', value: '${stats.weekBookings}'),
        StatTile(icon: Icons.payments_outlined, label: 'Revenue this month', value: formatMoney(stats.monthlyRevenue)),
        StatTile(icon: Icons.star_outline, label: 'Average rating', value: formatRating(stats.averageRating)),
        StatTile(icon: Icons.local_offer_outlined, label: 'Active promotions', value: '${stats.activePromotions}'),
        StatTile(icon: Icons.pending_actions_outlined, label: 'Pending bookings', value: '${stats.pendingBookings}'),
        StatTile(icon: Icons.meeting_room_outlined, label: 'Active rooms', value: '${stats.activeRooms}'),
      ],
    );
  }
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 1000
          ? Column(children: [left, const SizedBox(height: 16), right])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                Expanded(child: right),
              ],
            ),
    );
  }
}

class _UpcomingSessions extends StatelessWidget {
  const _UpcomingSessions({required this.sessions, required this.onOpen});

  final List<UpcomingSessionDto> sessions;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const EmptyMessage('There are no upcoming sessions.');
    return Column(
      children: [
        for (final session in sessions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => onOpen(session.bookingId),
            leading: const Icon(Icons.event_outlined),
            title: Text('${session.roomName}, ${session.clientName}'),
            subtitle: Text(
              '${formatDate(session.date)} at ${session.startTime}, '
              '${session.playerCount == 1 ? '1 player' : '${session.playerCount} players'}',
            ),
            trailing: StatusChip(session.status, Tone.info),
          ),
      ],
    );
  }
}

class _LatestReviews extends StatelessWidget {
  const _LatestReviews({required this.reviews});

  final List<DashboardReviewDto> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const EmptyMessage('There are no reviews yet.');
    return Column(
      children: [
        for (final review in reviews)
          ReviewTile(
            title: '${review.roomName}, ${review.clientName}',
            rating: review.rating,
            comment: review.comment,
            createdAt: review.createdAt,
            isHidden: review.isHidden,
          ),
      ],
    );
  }
}
