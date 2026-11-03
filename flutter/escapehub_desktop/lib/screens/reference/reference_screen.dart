import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/actions.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import 'reference_form_dialog.dart';

class ReferenceScreen extends ConsumerStatefulWidget {
  const ReferenceScreen({super.key});

  @override
  ConsumerState<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends ConsumerState<ReferenceScreen> {
  final _search = TextEditingController();
  var _table = ReferenceTable.themes;
  ListSort? _sort;
  var _page = 1;
  late Future<Paged<ReferenceDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<ReferenceDto>> _load() => ref
      .read(apiClientProvider)
      .references
      .list(_table, search: optionalText(_search.text), sortBy: _sort, page: _page);

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  void _filter() {
    _sort = null;
    _reload();
  }

  void _selectTable(ReferenceTable table) {
    _search.clear();
    _table = table;
    _filter();
  }

  Future<void> _create() async {
    final created = await showReferenceForm(context, _table);
    if (created == null || !mounted) return;
    _search.clear();
    _sort = ListSort.newest;
    _reload();
  }

  Future<void> _edit(ReferenceDto item) async {
    final saved = await showReferenceForm(context, _table, item);
    if (saved == null || !mounted) return;
    if (_search.text == item.name) _search.text = saved.name;
    _reload(page: _page);
  }

  Future<void> _delete(ReferenceDto item) async {
    final table = _table;
    final deleted = await confirmAndRun(
      context,
      title: 'Delete the ${table.singular}',
      message: 'Do you want to delete the ${table.singular} ${item.name}? You cannot undo this action.',
      confirmLabel: 'Delete',
      destructive: true,
      action: () => ref.read(apiClientProvider).references.delete(table, item.id),
      success: 'The ${table.singular} ${item.name} was deleted.',
    );
    if (!deleted || !mounted) return;
    ref.invalidate(referenceProvider(table));
    _reload(page: _page);
  }

  String? get _detailColumn => switch (_table) {
    ReferenceTable.cities => 'Country',
    ReferenceTable.difficultyLevels => 'Difficulty value',
    ReferenceTable.promotionTypes || ReferenceTable.rewardTypes => 'Discount kind',
    _ => null,
  };

  static String _detail(ReferenceDto item) => switch (item) {
    CityDto(:final countryName) => countryName,
    DifficultyLevelDto(:final value) => '$value of 10',
    DiscountTypeDto(:final isPercentage) => isPercentage ? 'Percentage' : 'Fixed amount',
    _ => '',
  };

  String? _createBlockedReason() {
    if (_table != ReferenceTable.cities) return null;
    final countries = ref.watch(referenceProvider(ReferenceTable.countries)).value;
    return countries != null && countries.isEmpty ? 'Add a country first. Each city needs a country.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final detailColumn = _detailColumn;
    final blocked = _createBlockedReason();
    return ListPage(
      header: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final table in ReferenceTable.values)
            ChoiceChip(label: Text(table.title), selected: table == _table, onSelected: (_) => _selectTable(table)),
        ],
      ),
      filters: [SearchField(controller: _search, hint: 'Name', onChanged: (_) => _filter())],
      actions: [
        Tooltip(
          message: blocked ?? 'Add a new ${_table.singular}',
          child: FilledButton.icon(
            onPressed: blocked == null ? _create : null,
            icon: const Icon(Icons.add),
            label: Text('New ${_table.singular}'),
          ),
        ),
      ],
      child: PagedTable<ReferenceDto>(
        key: ValueKey(_table),
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        columns: ['Name', ?detailColumn, 'Used by', 'Actions'],
        cells: (item) => [
          Text(item.name),
          if (detailColumn != null) Text(_detail(item)),
          Text(item.usageCount == 1 ? '1 record' : '${item.usageCount} records'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionIcon(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: () => _edit(item)),
              ActionIcon(
                icon: Icons.delete_outline,
                tooltip: item.deleteBlockedReason ?? 'Delete',
                onPressed: item.canDelete ? () => _delete(item) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
