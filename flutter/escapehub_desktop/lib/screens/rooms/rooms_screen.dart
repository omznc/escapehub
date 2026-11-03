import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/actions.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/status_chip.dart';
import 'room_actions.dart';
import 'room_detail_screen.dart';
import 'room_form_dialog.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  final _search = TextEditingController();
  int? _themeId;
  int? _difficultyId;
  bool? _isActive;
  RoomSort? _sort;
  var _page = 1;
  late Future<Paged<RoomListItemDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<RoomListItemDto>> _load() {
    final user = ref.read(currentUserProvider);
    return ref
        .read(apiClientProvider)
        .rooms
        .list(
          RoomQuery(
            search: optionalText(_search.text),
            themeId: _themeId,
            difficultyLevelId: _difficultyId,
            isActive: _isActive,
            managerId: user != null && user.isRoomManager ? user.id : null,
            sortBy: _sort,
            page: _page,
          ),
        );
  }

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
    final room = await showRoomForm(context);
    if (room == null || !mounted) return;
    _themeId = null;
    _difficultyId = null;
    _isActive = null;
    _search.clear();
    _sort = RoomSort.newest;
    _reload();
  }

  Future<void> _edit(RoomListItemDto item) async {
    final room = await runLoad(context, () => ref.read(apiClientProvider).rooms.get(item.id));
    if (room == null || !mounted) return;
    final saved = await showRoomForm(context, room);
    if (saved == null || !mounted) return;
    if (_search.text == item.name) _search.text = saved.name;
    _reload(page: _page);
  }

  Future<void> _open(RoomListItemDto item) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RoomDetailScreen(roomId: item.id)));
    if (mounted) _reload(page: _page);
  }

  Future<void> _run(Future<bool> Function() action) async {
    if (await action() && mounted) _reload(page: _page);
  }

  String? _createBlockedReason() {
    final themes = ref.watch(referenceProvider(ReferenceTable.themes)).value;
    final levels = ref.watch(referenceProvider(ReferenceTable.difficultyLevels)).value;
    if (themes == null || levels == null || (themes.isNotEmpty && levels.isNotEmpty)) return null;
    final isAdministrator = ref.watch(currentUserProvider.select((user) => user?.isAdministrator ?? false));
    return isAdministrator
        ? 'A room needs a theme and a difficulty level. Add them in Reference data first.'
        : 'A room needs a theme and a difficulty level. Ask an administrator to add them.';
  }

  @override
  Widget build(BuildContext context) {
    final isAdministrator = ref.watch(currentUserProvider.select((user) => user?.isAdministrator ?? false));
    final blocked = _createBlockedReason();
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Room name', onChanged: (_) => _filter()),
        ReferenceFilter(
          table: ReferenceTable.themes,
          label: 'Theme',
          value: _themeId,
          onChanged: (value) => _filter(() => _themeId = value),
        ),
        ReferenceFilter(
          table: ReferenceTable.difficultyLevels,
          label: 'Difficulty',
          value: _difficultyId,
          onChanged: (value) => _filter(() => _difficultyId = value),
        ),
        FilterDropdown<bool>(
          label: 'Status',
          value: _isActive,
          options: const {true: 'Active', false: 'Archived'},
          onChanged: (value) => _filter(() => _isActive = value),
        ),
      ],
      actions: [
        Tooltip(
          message: blocked ?? 'Add a new room',
          child: FilledButton.icon(
            onPressed: blocked == null ? _create : null,
            icon: const Icon(Icons.add),
            label: const Text('New room'),
          ),
        ),
      ],
      child: PagedTable<RoomListItemDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        onTap: _open,
        columns: [
          'Room',
          'Difficulty',
          'Players',
          'Duration',
          'Price',
          'Rating',
          if (isAdministrator) 'Manager',
          'Status',
          'Actions',
        ],
        cells: (room) => [
          NameWithImage(name: room.name, imageUrl: room.imageUrl, subtitle: room.themeName),
          Text(room.difficultyName),
          Text('${room.minPlayers} to ${room.maxPlayers}'),
          Text('${room.durationMinutes} min'),
          Text('${formatMoney(room.pricePerPerson)} per person'),
          Text(formatRating(room.averageRating)),
          if (isAdministrator) Text(room.managerName ?? 'No manager'),
          StatusChip(room.isActive ? 'Active' : 'Archived', Tone.ofActive(room.isActive)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionIcon(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: () => _edit(room)),
              ActionIcon(
                icon: room.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                tooltip: room.isActive ? 'Archive' : 'Restore',
                onPressed: () => _run(() => toggleRoomArchive(context, ref, room)),
              ),
              ActionIcon(
                icon: Icons.delete_outline,
                tooltip: room.deleteBlockedReason ?? 'Delete',
                onPressed: room.canDelete == true ? () => _run(() => deleteRoom(context, ref, room)) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
