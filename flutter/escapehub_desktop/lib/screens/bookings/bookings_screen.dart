import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/room_dropdown.dart';
import '../../widgets/status_chip.dart';
import 'booking_create_dialog.dart';
import 'booking_detail_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  final _search = TextEditingController();
  BookingStatus? _status;
  int? _roomId;
  DateTimeRange? _range;
  ListSort? _sort;
  var _page = 1;
  late Future<Paged<BookingListItemDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<BookingListItemDto>> _load() => ref
      .read(apiClientProvider)
      .bookings
      .list(
        status: _status,
        roomId: _roomId,
        from: _range?.start,
        to: _range?.end,
        search: optionalText(_search.text),
        sortBy: _sort,
        page: _page,
      );

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  void _filter([VoidCallback? change]) {
    change?.call();
    _sort = null;
    _reload();
  }

  Future<void> _showDetail(int bookingId) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(bookingId: bookingId)));

  Future<void> _open(int bookingId) async {
    await _showDetail(bookingId);
    if (mounted) _reload(page: _page);
  }

  Future<void> _create() async {
    final created = await showBookingCreateDialog(context);
    if (created == null || !mounted) return;
    await _showDetail(created.id);
    if (!mounted) return;
    _status = null;
    _roomId = null;
    _range = null;
    _search.clear();
    _sort = ListSort.newest;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final blocked = noRoomsReason(ref, 'booking');
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Client, email or room', onChanged: (_) => _filter()),
        FilterDropdown<BookingStatus>(
          label: 'Status',
          value: _status,
          options: {for (final status in BookingStatus.values) status: bookingStatusLabel(status)},
          onChanged: (value) => _filter(() => _status = value),
        ),
        RoomFilter(value: _roomId, onChanged: (value) => _filter(() => _roomId = value)),
        DateRangeFilter(value: _range, onChanged: (value) => _filter(() => _range = value)),
      ],
      actions: [
        Tooltip(
          message: blocked ?? 'Create a booking for a client',
          child: FilledButton.icon(
            onPressed: blocked == null ? _create : null,
            icon: const Icon(Icons.add),
            label: const Text('New booking'),
          ),
        ),
      ],
      child: PagedTable<BookingListItemDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        onTap: (booking) => _open(booking.id),
        columns: const ['Room', 'Client', 'Date', 'Time', 'Players', 'Total', 'Status'],
        cells: (booking) => [
          NameWithImage(name: booking.roomName, imageUrl: booking.roomImageUrl, subtitle: booking.themeName),
          NameWithImage(name: booking.clientName, imageUrl: booking.clientPictureUrl, round: true),
          Text(formatDate(booking.date)),
          Text('${booking.startTime} to ${booking.endTime}'),
          Text('${booking.playerCount}'),
          Text(formatMoney(booking.totalPrice)),
          StatusChip(booking.statusName, Tone.ofBooking(booking.status)),
        ],
      ),
    );
  }
}
