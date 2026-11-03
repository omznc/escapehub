import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/status_chip.dart';
import '../bookings/booking_detail_screen.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final int clientId;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  late Future<UserDto> _client;
  late Future<LoyaltyBalanceDto> _balance;

  ClientsApi get _api => ref.read(apiClientProvider).clients;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _client = _api.get(widget.clientId);
    _balance = _api.loyalty(widget.clientId);
  }

  void _reload() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: DetailPage(
        title: 'Client details',
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Profile'),
            Tab(text: 'Bookings'),
            Tab(text: 'Loyalty transactions'),
            Tab(text: 'Reviews'),
          ],
        ),
        body: TabBarView(
          children: [
            FutureView<UserDto>(
              future: _client,
              onRetry: _reload,
              builder: (context, client) => _ProfileTab(client: client, balance: _balance),
            ),
            _BookingsTab(clientId: widget.clientId),
            _TransactionsTab(clientId: widget.clientId),
            _ReviewsTab(clientId: widget.clientId),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.client, required this.balance});

  final UserDto client;
  final Future<LoyaltyBalanceDto> balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApiImage(
                  path: client.profilePictureUrl,
                  label: client.fullName,
                  width: 120,
                  height: 120,
                  borderRadius: BorderRadius.circular(60),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(client.fullName, style: theme.textTheme.headlineSmall),
                          const SizedBox(width: 12),
                          StatusChip(client.isActive ? 'Active' : 'Inactive', Tone.ofActive(client.isActive)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoRow(icon: Icons.person_outline, label: 'Username', value: client.username),
                      InfoRow(icon: Icons.mail_outline, label: 'Email', value: client.email),
                      InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: client.phone ?? 'No phone'),
                      InfoRow(
                        icon: Icons.location_city_outlined,
                        label: 'City',
                        value: [client.cityName, client.countryName].nonNulls.join(', '),
                      ),
                      InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member since',
                        value: formatDate(client.createdAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _LoyaltyTiles(balance: balance),
      ],
    );
  }
}

class _LoyaltyTiles extends StatelessWidget {
  const _LoyaltyTiles({required this.balance});

  final Future<LoyaltyBalanceDto> balance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltyBalanceDto>(
      future: balance,
      builder: (context, snapshot) {
        final error = snapshot.error;
        if (error != null) return Text('$error', style: TextStyle(color: Theme.of(context).colorScheme.error));
        final data = snapshot.data;
        if (data == null) return const LinearProgressIndicator();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatTile(icon: Icons.loyalty_outlined, label: 'Points balance', value: '${data.balance}'),
            StatTile(icon: Icons.add_circle_outline, label: 'Points earned', value: '${data.earnedTotal}'),
            StatTile(icon: Icons.redeem_outlined, label: 'Points redeemed', value: '${data.redeemedTotal}'),
          ],
        );
      },
    );
  }
}

class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab({required this.clientId});

  final int clientId;

  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab> {
  BookingStatus? _status;
  var _page = 1;
  late Future<Paged<BookingListItemDto>> _future = _load();

  Future<Paged<BookingListItemDto>> _load() =>
      ref.read(apiClientProvider).clients.bookings(widget.clientId, status: _status, page: _page);

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  Future<void> _open(BookingListItemDto booking) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(bookingId: booking.id)));
    if (mounted) _reload(page: _page);
  }

  @override
  Widget build(BuildContext context) {
    return _TabList(
      filters: [
        FilterDropdown<BookingStatus>(
          label: 'Status',
          value: _status,
          options: {for (final status in BookingStatus.values) status: bookingStatusLabel(status)},
          onChanged: (value) {
            _status = value;
            _reload();
          },
        ),
      ],
      child: PagedTable<BookingListItemDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        onTap: _open,
        emptyMessage: 'The client has no bookings with this status.',
        columns: const ['Room', 'Date', 'Time', 'Players', 'Total', 'Status'],
        cells: (booking) => [
          NameWithImage(name: booking.roomName, imageUrl: booking.roomImageUrl, subtitle: booking.themeName),
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

class _TransactionsTab extends ConsumerStatefulWidget {
  const _TransactionsTab({required this.clientId});

  final int clientId;

  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab> {
  TransactionType? _type;
  DateTimeRange? _range;
  var _page = 1;
  late Future<Paged<LoyaltyTransactionDto>> _future = _load();

  Future<Paged<LoyaltyTransactionDto>> _load() => ref
      .read(apiClientProvider)
      .clients
      .transactions(widget.clientId, type: _type, from: _range?.start, to: _range?.end, page: _page);

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return _TabList(
      filters: [
        FilterDropdown<TransactionType>(
          label: 'Type',
          value: _type,
          options: {for (final type in TransactionType.values) type: type.value},
          onChanged: (value) {
            _type = value;
            _reload();
          },
        ),
        DateRangeFilter(
          value: _range,
          onChanged: (value) {
            _range = value;
            _reload();
          },
        ),
      ],
      child: PagedTable<LoyaltyTransactionDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        emptyMessage: 'The client has no loyalty transactions that match the filters.',
        columns: const ['Date', 'Type', 'Points', 'Description', 'Room'],
        cells: (transaction) => [
          Text(formatTimestamp(transaction.createdAt)),
          Text(transaction.type.value),
          Text(transaction.points > 0 ? '+${transaction.points}' : '${transaction.points}'),
          Text(transaction.description ?? ''),
          switch (transaction.roomName) {
            final room? => NameWithImage(name: room, imageUrl: transaction.roomImageUrl),
            null => const Text(''),
          },
        ],
      ),
    );
  }
}

class _ReviewsTab extends ConsumerStatefulWidget {
  const _ReviewsTab({required this.clientId});

  final int clientId;

  @override
  ConsumerState<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<_ReviewsTab> {
  int? _rating;
  var _page = 1;
  late Future<Paged<ReviewDto>> _future = _load();

  Future<Paged<ReviewDto>> _load() => ref
      .read(apiClientProvider)
      .reviews
      .list(ReviewQuery(clientId: widget.clientId, rating: _rating, includeHidden: true, page: _page));

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return _TabList(
      filters: [
        RatingFilter(
          value: _rating,
          onChanged: (value) {
            _rating = value;
            _reload();
          },
        ),
      ],
      child: PagedTable<ReviewDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        emptyMessage: 'The client has no reviews that match the filter.',
        columns: const ['Room', 'Rating', 'Comment', 'Date', 'Visibility'],
        cells: (review) => [
          NameWithImage(name: review.roomName, imageUrl: review.roomImageUrl),
          RatingStars(review.rating),
          SizedBox(
            width: 360,
            child: Text(review.comment ?? 'No comment', maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Text(formatDate(review.createdAt)),
          StatusChip(review.isHidden ? 'Hidden' : 'Visible', review.isHidden ? Tone.neutral : Tone.positive),
        ],
      ),
    );
  }
}

class _TabList extends StatelessWidget {
  const _TabList({required this.filters, required this.child});

  final List<Widget> filters;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filters.isNotEmpty) ...[Wrap(spacing: 12, children: filters), const SizedBox(height: 16)],
          Expanded(
            child: Card(clipBehavior: Clip.antiAlias, child: child),
          ),
        ],
      ),
    );
  }
}
