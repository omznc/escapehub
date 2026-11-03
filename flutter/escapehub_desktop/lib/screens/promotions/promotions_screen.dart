import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/actions.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/status_chip.dart';
import 'promotion_form_dialog.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  final _search = TextEditingController();
  bool? _isActive;
  bool? _currentlyValid;
  int? _roomId;
  ListSort? _sort;
  var _page = 1;
  late Future<Paged<PromotionDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  PromotionsApi get _api => ref.read(apiClientProvider).promotions;

  Future<Paged<PromotionDto>> _load() => _api.list(
    isActive: _isActive,
    currentlyValid: _currentlyValid,
    roomId: _roomId,
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

  Future<void> _create() async {
    final promotion = await showPromotionForm(context);
    if (promotion == null || !mounted) return;
    _isActive = null;
    _currentlyValid = null;
    _roomId = null;
    _search.clear();
    _sort = ListSort.newest;
    _reload();
  }

  Future<void> _edit(PromotionDto promotion) async {
    final saved = await showPromotionForm(context, promotion);
    if (saved == null || !mounted) return;
    if (_search.text == promotion.name) _search.text = saved.name;
    _reload(page: _page);
  }

  Future<void> _setActive(PromotionDto promotion, bool active) async {
    final done = active
        ? await runAction(
            context,
            () => _api.activate(promotion.id),
            'The promotion ${promotion.name} was activated.',
          )
        : await confirmAndRun(
            context,
            title: 'Deactivate the promotion',
            message:
                'Do you want to deactivate the promotion ${promotion.name}? '
                'Clients cannot use it for new bookings until you activate it again.',
            confirmLabel: 'Deactivate',
            destructive: true,
            action: () => _api.deactivate(promotion.id),
            success: 'The promotion ${promotion.name} was deactivated.',
          );
    if (done && mounted) _reload(page: _page);
  }

  Future<void> _delete(PromotionDto promotion) async {
    final done = await confirmAndRun(
      context,
      title: 'Delete the promotion',
      message: 'Do you want to delete the promotion ${promotion.name}? You cannot undo this action.',
      confirmLabel: 'Delete',
      destructive: true,
      action: () => _api.delete(promotion.id),
      success: 'The promotion ${promotion.name} was deleted.',
    );
    if (done && mounted) _reload(page: _page);
  }

  String? _lockedReason(PromotionDto promotion, UserDto? user, List<RoomListItemDto> rooms) {
    if (user == null || user.isAdministrator) return null;
    final own = {for (final room in rooms) room.id};
    final allOwn = !promotion.appliesToAllRooms && promotion.rooms.every((room) => own.contains(room.id));
    return allOwn ? null : 'Only an administrator can change a promotion for rooms that you do not manage.';
  }

  String? _createBlockedReason() {
    final types = ref.watch(referenceProvider(ReferenceTable.promotionTypes)).value;
    return types != null && types.isEmpty ? 'Add a promotion type in Reference data first.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final rooms = ref.watch(roomOptionsProvider).value ?? const <RoomListItemDto>[];
    final blocked = _createBlockedReason();
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Name or description', onChanged: (_) => _filter()),
        RoomFilter(value: _roomId, onChanged: (value) => _filter(() => _roomId = value)),
        FilterDropdown<bool>(
          label: 'Status',
          value: _isActive,
          options: const {true: 'Active', false: 'Inactive'},
          onChanged: (value) => _filter(() => _isActive = value),
        ),
        FilterDropdown<bool>(
          label: 'Validity',
          value: _currentlyValid,
          allLabel: 'Any date',
          options: const {true: 'Valid today'},
          onChanged: (value) => _filter(() => _currentlyValid = value),
        ),
      ],
      actions: [
        Tooltip(
          message: blocked ?? 'Add a new promotion',
          child: FilledButton.icon(
            onPressed: blocked == null ? _create : null,
            icon: const Icon(Icons.add),
            label: const Text('New promotion'),
          ),
        ),
      ],
      child: PagedTable<PromotionDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        columns: const ['Promotion', 'Discount', 'Valid', 'Rooms', 'Bookings', 'Active', 'Actions'],
        cells: (promotion) => _cells(promotion, _lockedReason(promotion, user, rooms)),
      ),
    );
  }

  List<Widget> _cells(PromotionDto promotion, String? locked) => [
    TwoLineText(title: promotion.name, subtitle: promotion.promotionTypeName),
    Text(formatDiscount(promotion.discountValue, isPercentage: promotion.isPercentage)),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatDateRange(promotion.startDate, promotion.endDate)),
        const SizedBox(width: 8),
        if (promotion.isCurrentlyValid) const StatusChip('Valid today', Tone.positive),
      ],
    ),
    SizedBox(
      width: 220,
      child: Text(
        promotion.appliesToAllRooms ? 'All rooms' : promotion.rooms.map((room) => room.name).join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Text('${promotion.bookingCount ?? 0}'),
    Tooltip(
      message: locked ?? (promotion.isActive ? 'Deactivate' : 'Activate'),
      child: Switch(
        value: promotion.isActive,
        onChanged: locked == null ? (value) => _setActive(promotion, value) : null,
      ),
    ),
    _actions(promotion, locked),
  ];

  Widget _actions(PromotionDto promotion, String? locked) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ActionIcon(
        icon: Icons.edit_outlined,
        tooltip: locked ?? 'Edit',
        onPressed: locked == null ? () => _edit(promotion) : null,
      ),
      ActionIcon(
        icon: Icons.delete_outline,
        tooltip: locked ?? promotion.deleteBlockedReason ?? 'Delete',
        onPressed: locked == null && promotion.canDelete == true ? () => _delete(promotion) : null,
      ),
    ],
  );
}
