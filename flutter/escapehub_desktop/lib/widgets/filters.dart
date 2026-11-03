import 'dart:async';

import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format.dart';
import '../providers.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.controller, required this.hint, required this.onChanged});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => widget.onChanged(value.trim()));
  }

  void _clear() {
    widget.controller.clear();
    _debounce?.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => TextField(
          controller: widget.controller,
          onChanged: _changed,
          maxLength: 100,
          decoration: InputDecoration(
            counterText: '',
            labelText: 'Search',
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.controller.text.isEmpty
                ? null
                : IconButton(tooltip: 'Clear the search', onPressed: _clear, icon: const Icon(Icons.close)),
          ),
        ),
      ),
    );
  }
}

class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allLabel = 'All',
    this.width = 200,
  });

  final String label;
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;
  final String? allLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final all = allLabel;
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T?>(
            value: value,
            isDense: true,
            isExpanded: true,
            onChanged: onChanged,
            items: [
              if (all != null) DropdownMenuItem<T?>(value: null, child: Text(all)),
              for (final MapEntry(:key, :value) in options.entries)
                DropdownMenuItem<T?>(
                  value: key,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomFilter extends ConsumerWidget {
  const RoomFilter({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomOptionsProvider).value ?? const <RoomListItemDto>[];
    return FilterDropdown<int>(
      label: 'Room',
      value: rooms.any((room) => room.id == value) ? value : null,
      allLabel: 'All rooms',
      width: 220,
      options: {for (final room in rooms) room.id: room.name},
      onChanged: onChanged,
    );
  }
}

class ReferenceFilter extends ConsumerWidget {
  const ReferenceFilter({
    super.key,
    required this.table,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final ReferenceTable table;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(referenceProvider(table)).value ?? const <ReferenceDto>[];
    return FilterDropdown<int>(
      label: label,
      value: items.any((item) => item.id == value) ? value : null,
      options: {for (final item in items) item.id: item.name},
      onChanged: onChanged,
    );
  }
}

class RatingFilter extends StatelessWidget {
  const RatingFilter({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterDropdown<int>(
      label: 'Rating',
      value: value,
      width: 150,
      options: {for (var stars = 5; stars >= 1; stars--) stars: stars == 1 ? '1 star' : '$stars stars'},
      onChanged: onChanged,
    );
  }
}

class DateRangeFilter extends StatelessWidget {
  const DateRangeFilter({super.key, required this.value, required this.onChanged, this.allowClear = true});

  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;
  final bool allowClear;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: value,
      firstDate: DateTime(2020),
      lastDate: DateTime(today().year + 2, 12, 31),
      helpText: 'Select a date range',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final range = value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pick(context),
          icon: const Icon(Icons.date_range_outlined),
          label: Text(range == null ? 'Any date' : formatDateRange(range.start, range.end)),
        ),
        if (range != null && allowClear)
          IconButton(tooltip: 'Clear the dates', onPressed: () => onChanged(null), icon: const Icon(Icons.close)),
      ],
    );
  }
}
