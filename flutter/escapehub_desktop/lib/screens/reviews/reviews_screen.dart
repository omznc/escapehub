import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/actions.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/status_chip.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final _search = TextEditingController();
  int? _roomId;
  int? _rating;
  DateTimeRange? _range;
  var _includeHidden = true;
  var _page = 1;
  late Future<Paged<ReviewDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ReviewsApi get _api => ref.read(apiClientProvider).reviews;

  Future<Paged<ReviewDto>> _load() => _api.list(
    ReviewQuery(
      roomId: _roomId,
      rating: _rating,
      from: _range?.start,
      to: _range?.end,
      includeHidden: _includeHidden,
      search: optionalText(_search.text),
      page: _page,
    ),
  );

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  void _filter(VoidCallback change) {
    change();
    _reload();
  }

  Future<void> _toggleHidden(ReviewDto review) async {
    final hide = !review.isHidden;
    final done = await confirmAndRun(
      context,
      title: hide ? 'Hide the review' : 'Show the review',
      message: hide
          ? 'Do you want to hide the review of ${review.clientName} for ${review.roomName}? '
                'Clients will not see it, and it will not count in the room rating.'
          : 'Do you want to show the review of ${review.clientName} for ${review.roomName} to clients again?',
      confirmLabel: hide ? 'Hide' : 'Show',
      destructive: hide,
      action: () => hide ? _api.hide(review.id) : _api.unhide(review.id),
      success: hide
          ? 'The review of ${review.clientName} was hidden.'
          : 'The review of ${review.clientName} is visible again.',
    );
    if (done && mounted) _reload(page: _page);
  }

  @override
  Widget build(BuildContext context) {
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Client, room or comment', onChanged: (_) => _reload()),
        RoomFilter(value: _roomId, onChanged: (value) => _filter(() => _roomId = value)),
        RatingFilter(value: _rating, onChanged: (value) => _filter(() => _rating = value)),
        DateRangeFilter(value: _range, onChanged: (value) => _filter(() => _range = value)),
        FilterChip(
          label: const Text('Show hidden reviews'),
          selected: _includeHidden,
          onSelected: (value) => _filter(() => _includeHidden = value),
        ),
      ],
      child: PagedTable<ReviewDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        columns: const ['Room', 'Client', 'Rating', 'Comment', 'Date', 'Visibility', 'Actions'],
        cells: (review) => [
          NameWithImage(name: review.roomName, imageUrl: review.roomImageUrl),
          NameWithImage(name: review.clientName, imageUrl: review.clientPictureUrl, round: true),
          RatingStars(review.rating),
          SizedBox(
            width: 300,
            child: Text(review.comment ?? 'No comment', maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Text(formatTimestamp(review.createdAt)),
          StatusChip(review.isHidden ? 'Hidden' : 'Visible', review.isHidden ? Tone.neutral : Tone.positive),
          ActionIcon(
            icon: review.isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            tooltip: review.isHidden ? 'Show to clients' : 'Hide from clients',
            onPressed: () => _toggleHidden(review),
          ),
        ],
      ),
    );
  }
}
