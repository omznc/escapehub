import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/rating_stars.dart';
import '../../widgets/section_header.dart';
import '../booking/booking_form_screen.dart';
import 'reviews_section.dart';
import 'room_facts.dart';
import 'room_gallery.dart';
import 'room_providers.dart';
import 'slot_picker.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId, this.date});

  final int roomId;
  final DateTime? date;

  static Future<void> open(BuildContext context, int roomId, {DateTime? date}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => RoomDetailScreen(roomId: roomId, date: date),
    ),
  );

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  late DateTime _date = widget.date ?? DateUtils.dateOnly(DateTime.now());
  SlotDto? _slot;

  Future<void> _book(RoomDto room, SlotDto slot) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BookingFormScreen(room: room, slot: slot),
      ),
    );
    if (!mounted) return;
    setState(() => _slot = null);
    ref.invalidate(slotsProvider((room.id, _date)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(roomDetailProvider(widget.roomId));
    final room = detail.value?.$1;
    final slot = _slot;
    return Scaffold(
      appBar: AppBar(title: Text(room?.name ?? 'Room')),
      body: detail.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(roomDetailProvider(widget.roomId))),
        data: (data) => _RoomBody(
          room: data.$1,
          reviews: data.$2,
          date: _date,
          slot: slot,
          onDate: (date) => setState(() {
            _date = date;
            _slot = null;
          }),
          onSlot: (slot) => setState(() => _slot = slot),
        ),
      ),
      bottomNavigationBar: room == null
          ? null
          : _BookBar(slot: slot, onBook: slot == null ? null : () => _book(room, slot)),
    );
  }
}

class _RoomBody extends StatelessWidget {
  const _RoomBody({
    required this.room,
    required this.reviews,
    required this.date,
    required this.slot,
    required this.onDate,
    required this.onSlot,
  });

  final RoomDto room;
  final Paged<ReviewDto> reviews;
  final DateTime date;
  final SlotDto? slot;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<SlotDto> onSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        RoomGallery(images: [?room.imageUrl], label: room.name),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              RatingSummary(rating: room.averageRating, count: room.reviewCount),
              const SizedBox(height: 12),
              RoomFacts(room: room),
            ],
          ),
        ),
        const SectionHeader('About the room'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(room.longDescription)),
        for (final scenario in room.scenarios) _ScenarioCard(scenario: scenario),
        const SectionHeader('Pick a date and time'),
        SlotPicker(roomId: room.id, date: date, selected: slot, onDate: onDate, onSlot: onSlot),
        SectionHeader('Reviews (${room.reviewCount})'),
        ReviewsSection(reviews: reviews.items, averageRating: room.averageRating),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});

  final RoomScenarioSummaryDto scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Story: ${scenario.name}', style: theme.textTheme.titleSmall)),
                ],
              ),
              const SizedBox(height: 8),
              Text(scenario.story),
              if (scenario.hintPolicy case final policy?) ...[
                const SizedBox(height: 8),
                Text('Hints: $policy', style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BookBar extends StatelessWidget {
  const _BookBar({required this.slot, required this.onBook});

  final SlotDto? slot;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final selected = slot;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: onBook,
          icon: const Icon(Icons.event_available),
          label: Text(selected == null ? 'Select an available time to book' : 'Book ${selected.startTime}'),
        ),
      ),
    );
  }
}
