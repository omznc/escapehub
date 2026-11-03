import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/actions.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/room_dropdown.dart';
import '../../widgets/status_chip.dart';
import 'scenario_form_dialog.dart';

class ScenariosScreen extends ConsumerStatefulWidget {
  const ScenariosScreen({super.key});

  @override
  ConsumerState<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends ConsumerState<ScenariosScreen> {
  final _search = TextEditingController();
  int? _roomId;
  bool? _isActive;
  ListSort? _sort;
  var _page = 1;
  late Future<Paged<RoomScenarioDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<RoomScenarioDto>> _load() => ref
      .read(apiClientProvider)
      .scenarios
      .list(roomId: _roomId, isActive: _isActive, search: optionalText(_search.text), sortBy: _sort, page: _page);

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  void _filter([VoidCallback? change]) {
    change?.call();
    _sort = null;
    _reload();
  }

  Future<void> _create() async {
    final scenario = await showScenarioForm(context);
    if (scenario == null || !mounted) return;
    _roomId = null;
    _isActive = null;
    _search.clear();
    _sort = ListSort.newest;
    _reload();
  }

  Future<void> _edit(RoomScenarioDto scenario) async {
    final saved = await showScenarioForm(context, scenario);
    if (saved == null || !mounted) return;
    if (_search.text == scenario.name) _search.text = saved.name;
    _reload(page: _page);
  }

  Future<void> _delete(RoomScenarioDto scenario) async {
    final deleted = await confirmAndRun(
      context,
      title: 'Delete the scenario',
      message: 'Do you want to delete the scenario ${scenario.name} of the room ${scenario.roomName}?',
      confirmLabel: 'Delete',
      destructive: true,
      action: () => ref.read(apiClientProvider).scenarios.delete(scenario.id),
      success: 'The scenario ${scenario.name} was deleted.',
    );
    if (deleted && mounted) _reload(page: _page);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = noRoomsReason(ref, 'scenario');
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Scenario name', onChanged: (_) => _filter()),
        RoomFilter(value: _roomId, onChanged: (value) => _filter(() => _roomId = value)),
        FilterDropdown<bool>(
          label: 'Status',
          value: _isActive,
          options: const {true: 'Active', false: 'Inactive'},
          onChanged: (value) => _filter(() => _isActive = value),
        ),
      ],
      actions: [
        Tooltip(
          message: blocked ?? 'Add a new scenario',
          child: FilledButton.icon(
            onPressed: blocked == null ? _create : null,
            icon: const Icon(Icons.add),
            label: const Text('New scenario'),
          ),
        ),
      ],
      child: PagedTable<RoomScenarioDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        onTap: _edit,
        columns: const ['Scenario', 'Room', 'Difficulty', 'Hint policy', 'Status', 'Actions'],
        cells: (scenario) => [
          SizedBox(
            width: 260,
            child: Text(scenario.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          NameWithImage(name: scenario.roomName, imageUrl: scenario.roomImageUrl),
          Text(scenario.difficultyName ?? 'Same as the room'),
          SizedBox(
            width: 280,
            child: Text(scenario.hintPolicy ?? 'No hint policy', maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          StatusChip(scenario.isActive ? 'Active' : 'Inactive', Tone.ofActive(scenario.isActive)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionIcon(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: () => _edit(scenario)),
              ActionIcon(icon: Icons.delete_outline, tooltip: 'Delete', onPressed: () => _delete(scenario)),
            ],
          ),
        ],
      ),
    );
  }
}
