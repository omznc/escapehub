import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formatting.dart';
import 'room_filters.dart';

Future<RoomFilters?> showFilterSheet(BuildContext context, RoomFilters current) => showModalBottomSheet<RoomFilters>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => FilterSheet(initial: current),
);

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key, required this.initial});

  final RoomFilters initial;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  static const _partySizes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  late RoomFilters _filters = widget.initial;

  void _update({
    int? Function()? themeId,
    int? Function()? difficultyLevelId,
    int? Function()? partySize,
    RangeValues? Function()? price,
    DateTime? Function()? date,
  }) {
    setState(() {
      _filters = (
        themeId: themeId == null ? _filters.themeId : themeId(),
        difficultyLevelId: difficultyLevelId == null ? _filters.difficultyLevelId : difficultyLevelId(),
        partySize: partySize == null ? _filters.partySize : partySize(),
        price: price == null ? _filters.price : price(),
        date: date == null ? _filters.date : date(),
      );
    });
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _filters.date ?? today,
      firstDate: today,
      lastDate: DateUtils.addDaysToDate(today, 90),
      helpText: 'Available on',
    );
    if (date != null) _update(date: () => date);
  }

  @override
  Widget build(BuildContext context) {
    final themes = ref.watch(referenceProvider(ReferenceTable.themes));
    final levels = ref.watch(referenceProvider(ReferenceTable.difficultyLevels));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetTitle(onReset: () => setState(() => _filters = noFilters)),
            _ChipGroup(
              title: 'Theme',
              options: themes,
              selected: _filters.themeId,
              onSelected: (id) => _update(themeId: () => id),
            ),
            _ChipGroup(
              title: 'Difficulty',
              options: levels.whenData(_byDifficulty),
              selected: _filters.difficultyLevelId,
              onSelected: (id) => _update(difficultyLevelId: () => id),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _filters.partySize,
              decoration: const InputDecoration(labelText: 'Party size', prefixIcon: Icon(Icons.group_outlined)),
              items: [
                const DropdownMenuItem(child: Text('Any party size')),
                for (final size in _partySizes) DropdownMenuItem(value: size, child: Text(formatPlayerCount(size))),
              ],
              onChanged: (size) => _update(partySize: () => size),
            ),
            const SizedBox(height: 16),
            _PriceFilter(
              price: _filters.price,
              onChanged: (price) => _update(price: () => price),
            ),
            const SizedBox(height: 8),
            _DateFilter(
              date: _filters.date,
              onPick: _pickDate,
              onClear: () => _update(date: () => null),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.of(context).pop(_filters), child: const Text('Show rooms')),
          ],
        ),
      ),
    );
  }

  static List<ReferenceDto> _byDifficulty(List<ReferenceDto> levels) =>
      levels.cast<DifficultyLevelDto>().toList()..sort((a, b) => a.value.compareTo(b.value));
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Filters', style: Theme.of(context).textTheme.titleLarge)),
        TextButton(onPressed: onReset, child: const Text('Reset')),
        IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.title, required this.options, required this.selected, required this.onSelected});

  final String title;
  final AsyncValue<List<ReferenceDto>> options;
  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        options.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('$error'),
          data: (items) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(label: const Text('Any'), selected: selected == null, onSelected: (_) => onSelected(null)),
              for (final item in items)
                ChoiceChip(
                  label: Text(item.name),
                  selected: selected == item.id,
                  onSelected: (_) => onSelected(item.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceFilter extends ConsumerWidget {
  const _PriceFilter({required this.price, required this.onChanged});

  final RangeValues? price;
  final ValueChanged<RangeValues?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bounds = ref.watch(priceBoundsProvider);
    return bounds.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('$error'),
      data: (bounds) {
        if (bounds.start >= bounds.end) return const SizedBox.shrink();
        final values = price ?? bounds;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price per person: ${formatMoney(values.start)} - ${formatMoney(values.end)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            RangeSlider(
              values: values,
              min: bounds.start,
              max: bounds.end,
              divisions: (bounds.end - bounds.start).round(),
              labels: RangeLabels(formatMoney(values.start), formatMoney(values.end)),
              onChanged: (values) => onChanged(values == bounds ? null : values),
            ),
          ],
        );
      },
    );
  }
}

class _DateFilter extends StatelessWidget {
  const _DateFilter({required this.date, required this.onPick, required this.onClear});

  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = date;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Available on',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: selected == null
            ? null
            : IconButton(tooltip: 'Clear date', icon: const Icon(Icons.close), onPressed: onClear),
      ),
      child: InkWell(onTap: onPick, child: Text(selected == null ? 'Any date' : formatDay(selected))),
    );
  }
}
