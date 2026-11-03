import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/status_chip.dart';
import 'room_actions.dart';
import 'room_form_dialog.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  var _range = DateTimeRange(start: addDays(today(), -90), end: today());
  int? _rating;
  var _reviewsPage = 1;
  late Future<RoomDto> _room;
  late Future<RoomStatsDto> _stats;
  late Future<Paged<ReviewDto>> _reviews;

  RoomsApi get _api => ref.read(apiClientProvider).rooms;

  @override
  void initState() {
    super.initState();
    _room = _api.get(widget.roomId);
    _stats = _loadStats();
    _reviews = _loadReviews();
  }

  Future<RoomStatsDto> _loadStats() => _api.stats(widget.roomId, from: _range.start, to: _range.end);

  Future<Paged<ReviewDto>> _loadReviews() => ref
      .read(apiClientProvider)
      .reviews
      .list(ReviewQuery(roomId: widget.roomId, rating: _rating, page: _reviewsPage, pageSize: 10));

  void _reloadRoom() => setState(() => _room = _api.get(widget.roomId));

  Future<void> _edit(RoomDto room) async {
    if (await showRoomForm(context, room) != null && mounted) _reloadRoom();
  }

  Future<void> _toggleArchive(RoomDto room) async {
    if (await toggleRoomArchive(context, ref, room) && mounted) _reloadRoom();
  }

  void _filterReviews(int? rating) => setState(() {
    _rating = rating;
    _reviewsPage = 1;
    _reviews = _loadReviews();
  });

  void _changeRange(DateTimeRange? range) {
    if (range == null) return;
    setState(() {
      _range = range;
      _stats = _loadStats();
    });
  }

  void _changeReviewsPage(int page) => setState(() {
    _reviewsPage = page;
    _reviews = _loadReviews();
  });

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Room details',
      body: FutureView<RoomDto>(
        future: _room,
        onRetry: _reloadRoom,
        builder: (context, room) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _RoomHeader(room: room, onEdit: () => _edit(room), onToggleArchive: () => _toggleArchive(room)),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Statistics',
              actions: [DateRangeFilter(value: _range, allowClear: false, onChanged: _changeRange)],
              child: FutureView<RoomStatsDto>(
                future: _stats,
                onRetry: () => _changeRange(_range),
                builder: (context, stats) => _RoomStats(stats: stats),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Scenarios',
              child: _Scenarios(scenarios: room.scenarios),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Reviews',
              actions: [RatingFilter(value: _rating, onChanged: _filterReviews)],
              child: FutureView<Paged<ReviewDto>>(
                future: _reviews,
                onRetry: () => _changeReviewsPage(_reviewsPage),
                builder: (context, page) => _Reviews(page: page, onPage: _changeReviewsPage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.room, required this.onEdit, required this.onToggleArchive});

  final RoomDto room;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApiImage(
              path: room.imageUrl,
              label: room.name,
              width: 320,
              height: 220,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(room.name, style: theme.textTheme.headlineSmall)),
                      const SizedBox(width: 12),
                      StatusChip(room.isActive ? 'Active' : 'Archived', Tone.ofActive(room.isActive)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: onToggleArchive,
                        icon: Icon(room.isActive ? Icons.archive_outlined : Icons.unarchive_outlined),
                        label: Text(room.isActive ? 'Archive' : 'Restore'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(room.shortDescription),
                  if (room.longDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(room.longDescription, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  _RoomFacts(room: room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomFacts extends StatelessWidget {
  const _RoomFacts({required this.room});

  final RoomDto room;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              InfoRow(icon: Icons.category_outlined, label: 'Theme', value: room.themeName),
              InfoRow(icon: Icons.speed_outlined, label: 'Difficulty', value: room.difficultyName),
              InfoRow(icon: Icons.groups_outlined, label: 'Players', value: '${room.minPlayers} to ${room.maxPlayers}'),
              InfoRow(icon: Icons.timer_outlined, label: 'Duration', value: '${room.durationMinutes} minutes'),
              InfoRow(icon: Icons.family_restroom_outlined, label: 'Age', value: room.ageRecommendation ?? 'Any age'),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              InfoRow(
                icon: Icons.payments_outlined,
                label: 'Price per person',
                value: formatMoney(room.pricePerPerson),
              ),
              InfoRow(
                icon: Icons.payments_outlined,
                label: 'Price per booking',
                value: formatMoney(room.pricePerBooking),
              ),
              InfoRow(icon: Icons.location_city_outlined, label: 'City', value: room.cityName ?? 'No city'),
              InfoRow(icon: Icons.badge_outlined, label: 'Room manager', value: room.managerName ?? 'No manager'),
              InfoRow(
                icon: Icons.star_outline,
                label: 'Rating',
                value:
                    '${formatRating(room.averageRating)} (${room.reviewCount == 1 ? '1 review' : '${room.reviewCount} reviews'})',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomStats extends StatelessWidget {
  const _RoomStats({required this.stats});

  final RoomStatsDto stats;

  @override
  Widget build(BuildContext context) {
    final average = stats.averageCompletionMinutes;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        StatTile(icon: Icons.event_note_outlined, label: 'Bookings', value: '${stats.totalBookings}'),
        StatTile(icon: Icons.task_alt, label: 'Completed bookings', value: '${stats.completedBookings}'),
        StatTile(icon: Icons.event_busy_outlined, label: 'Cancelled bookings', value: '${stats.cancelledBookings}'),
        StatTile(icon: Icons.payments_outlined, label: 'Revenue', value: formatMoney(stats.revenue)),
        StatTile(
          icon: Icons.pie_chart_outline,
          label: 'Occupancy (${stats.bookedSlots} of ${stats.totalSlots} slots)',
          value: formatPercent(stats.occupancyPercent),
        ),
        StatTile(icon: Icons.star_outline, label: 'Average rating', value: formatRating(stats.averageRating)),
        StatTile(
          icon: Icons.door_back_door_outlined,
          label: 'Escape rate',
          value: formatPercent(stats.escapeRatePercent),
        ),
        StatTile(
          icon: Icons.timer_outlined,
          label: 'Average escape time',
          value: average == null ? 'No results' : '${average.toStringAsFixed(0)} min',
        ),
      ],
    );
  }
}

class _Scenarios extends StatelessWidget {
  const _Scenarios({required this.scenarios});

  final List<RoomScenarioSummaryDto> scenarios;

  @override
  Widget build(BuildContext context) {
    if (scenarios.isEmpty) return const EmptyMessage('This room has no active scenarios.');
    return Column(
      children: [
        for (final scenario in scenarios)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_stories_outlined),
            title: Text(scenario.name),
            subtitle: Text(scenario.story, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Text(scenario.difficultyName ?? 'Room difficulty'),
          ),
      ],
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.page, required this.onPage});

  final Paged<ReviewDto> page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) return const EmptyMessage('There are no reviews to show.');
    return Column(
      children: [
        for (final review in page.items)
          ReviewTile(
            title: review.clientName,
            leading: ApiImage(
              path: review.clientPictureUrl,
              label: review.clientName,
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
            rating: review.rating,
            comment: review.comment,
            createdAt: review.createdAt,
            isHidden: review.isHidden,
          ),
        Pager(page: page, onPage: onPage),
      ],
    );
  }
}
