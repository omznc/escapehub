import 'dart:async';

import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/notifications_button.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/room_card.dart';
import '../room/room_detail_screen.dart';
import 'filter_sheet.dart';
import 'room_filters.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  RoomFilters _filters = noFilters;
  RoomSort _sort = RoomSort.rating;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => setState(() => _search = value.trim()));
  }

  Future<void> _openFilters() async {
    final filters = await showFilterSheet(context, _filters);
    if (filters != null) setState(() => _filters = filters);
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiClientProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Explore rooms'), actions: const [NotificationsButton()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _SearchRow(
              controller: _searchController,
              onChanged: _onSearchChanged,
              filterCount: activeFilterCount(_filters),
              onFilters: _openFilters,
            ),
          ),
          _SortRow(
            sort: _sort,
            onSort: (sort) => setState(() => _sort = sort),
            onClearFilters: activeFilterCount(_filters) == 0 ? null : () => setState(() => _filters = noFilters),
          ),
          Expanded(
            child: PagedListView<RoomListItemDto>(
              reloadKey: (_filters, _sort, _search),
              fetch: (page) => api.rooms.list(roomQuery(_filters, _sort, _search, page)),
              emptyIcon: Icons.search_off,
              emptyMessage: 'No rooms match the search and the filters. Change or clear the filters.',
              itemBuilder: (context, room) => RoomCard(
                room: room,
                onTap: () => RoomDetailScreen.open(context, room.id, date: _filters.date),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.filterCount,
    required this.onFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int filterCount;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search by room name',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Filters',
          onPressed: onFilters,
          icon: Badge(isLabelVisible: filterCount > 0, label: Text('$filterCount'), child: const Icon(Icons.tune)),
        ),
      ],
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.sort, required this.onSort, required this.onClearFilters});

  final RoomSort sort;
  final ValueChanged<RoomSort> onSort;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PopupMenuButton<RoomSort>(
            tooltip: 'Sort rooms',
            initialValue: sort,
            onSelected: onSort,
            itemBuilder: (context) => [
              for (final MapEntry(key: value, value: label) in sortLabels.entries)
                CheckedPopupMenuItem(value: value, checked: value == sort, child: Text(label)),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [const Icon(Icons.sort, size: 20), const SizedBox(width: 8), Text(sortLabels[sort]!)],
              ),
            ),
          ),
          const Spacer(),
          if (onClearFilters != null) TextButton(onPressed: onClearFilters, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}
