import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../widgets/notifications_button.dart';
import '../../widgets/paged_list_view.dart';
import 'booking_detail_provider.dart';
import 'booking_list_tile.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(newBookingProvider, (previous, next) {
      if (next != null && next.id != previous?.id) _tabs.animateTo(0);
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('My bookings'),
        actions: const [NotificationsButton()],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_BookingList(upcoming: true), _BookingList(upcoming: false)],
      ),
    );
  }
}

bool _isUpcoming(BookingListItemDto booking) {
  final active = booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed;
  final [hour, minute] = booking.startTime.split(':').map(int.parse).toList();
  final start = booking.date.copyWith(hour: hour, minute: minute);
  return active && start.isAfter(DateTime.now());
}

class _BookingList extends ConsumerWidget {
  const _BookingList({required this.upcoming});

  final bool upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    final revision = ref.watch(bookingsRevisionProvider);
    final newBooking = upcoming ? ref.watch(newBookingProvider) : null;
    final latest = newBooking == null ? null : ref.watch(bookingProvider(newBooking.id)).value ?? newBooking;
    final pinned = latest != null && _isUpcoming(latest) ? latest : null;
    return PagedListView<BookingListItemDto>(
      reloadKey: revision,
      fetch: (page) => api.bookings.mine(upcoming: upcoming, page: page),
      emptyIcon: upcoming ? Icons.event_available_outlined : Icons.history,
      emptyMessage: upcoming
          ? 'You have no upcoming bookings. Pick a room in Explore to book a session.'
          : 'Your past, cancelled and completed bookings show here.',
      exclude: (booking) => booking.id == pinned?.id,
      header: pinned == null ? null : _NewBookingHeader(booking: pinned),
      itemBuilder: (context, booking) => BookingListTile(booking: booking),
    );
  }
}

class _NewBookingHeader extends StatelessWidget {
  const _NewBookingHeader({required this.booking});

  final BookingListItemDto booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest booking', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          BookingListTile(booking: booking, highlighted: true),
        ],
      ),
    );
  }
}
