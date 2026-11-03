import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/filters.dart';
import '../../widgets/pages.dart';
import '../../widgets/room_dropdown.dart';
import '../../widgets/status_chip.dart';
import 'generate_dialog.dart';
import 'schedule_dialog.dart';
import 'schedule_grid.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  int? _roomId;
  SlotStatus? _status;
  var _week = startOfWeek(today());
  late Future<List<ScheduleDto>> _future = _load();

  DateTime get _weekEnd => addDays(_week, 6);

  Future<List<ScheduleDto>> _load() async {
    final api = ref.read(apiClientProvider).schedules;
    Future<Paged<ScheduleDto>> page(int number) =>
        api.list(roomId: _roomId, status: _status, from: _week, to: _weekEnd, page: number);
    final first = await page(1);
    final rest = await Future.wait([for (var number = 2; number <= first.totalPages; number++) page(number)]);
    return [...first.items, for (final next in rest) ...next.items];
  }

  void _reload() => setState(() => _future = _load());

  void _filter(VoidCallback change) {
    change();
    _reload();
  }

  void _showWeek(DateTime date) => _filter(() => _week = startOfWeek(date));

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _week,
      firstDate: DateTime(2020),
      lastDate: DateTime(today().year + 2, 12, 31),
      helpText: 'Select a day of the week to show',
    );
    if (picked != null && mounted) _showWeek(picked);
  }

  Future<void> _create({int? roomId, DateTime? date}) async {
    final saved = await showScheduleDialog(context, roomId: roomId ?? _roomId, date: date);
    if (saved != null && mounted) _showWeek(saved);
  }

  Future<void> _open(ScheduleDto schedule) async {
    final saved = await showScheduleDialog(context, schedule: schedule);
    if (saved != null && mounted) _showWeek(saved);
  }

  Future<void> _generate() async {
    final start = await showGenerateDialog(context, roomId: _roomId);
    if (start != null && mounted) _showWeek(start);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = noRoomsReason(ref, 'time slot');
    final rooms = ref.watch(roomOptionsProvider).value ?? const <RoomListItemDto>[];
    final shown = [
      for (final room in rooms)
        if (_roomId == null || room.id == _roomId) room,
    ];
    return ListPage(
      filters: [
        RoomFilter(value: _roomId, onChanged: (value) => _filter(() => _roomId = value)),
        FilterDropdown<SlotStatus>(
          label: 'Status',
          value: _status,
          options: {for (final status in SlotStatus.values) status: status.value},
          onChanged: (value) => _filter(() => _status = value),
        ),
        _WeekPicker(
          week: _week,
          onPrevious: () => _showWeek(addDays(_week, -7)),
          onNext: () => _showWeek(addDays(_week, 7)),
          onPick: _pickWeek,
          onToday: () => _showWeek(today()),
        ),
      ],
      actions: [
        Tooltip(
          message: blocked ?? 'Create time slots for many days at once',
          child: OutlinedButton.icon(
            onPressed: blocked == null ? _generate : null,
            icon: const Icon(Icons.auto_awesome_motion_outlined),
            label: const Text('Generate slots'),
          ),
        ),
        Tooltip(
          message: blocked ?? 'Add one time slot',
          child: FilledButton.icon(
            onPressed: blocked == null ? _create : null,
            icon: const Icon(Icons.add),
            label: const Text('New time slot'),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Legend(),
          const Divider(height: 1),
          Expanded(
            child: FutureView<List<ScheduleDto>>(
              future: _future,
              onRetry: _reload,
              builder: (context, schedules) => shown.isEmpty
                  ? EmptyMessage(blocked ?? 'There are no rooms to show.')
                  : ScheduleGrid(
                      week: _week,
                      rooms: shown,
                      schedules: schedules,
                      onOpen: _open,
                      onAdd: (room, date) => _create(roomId: room.id, date: date),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPicker extends StatelessWidget {
  const _WeekPicker({
    required this.week,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    required this.onToday,
  });

  final DateTime week;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(tooltip: 'Previous week', onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(formatDateRange(week, addDays(week, 6))),
        ),
        IconButton(tooltip: 'Next week', onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        TextButton(onPressed: onToday, child: const Text('This week')),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Legend:', style: Theme.of(context).textTheme.labelLarge),
          for (final status in SlotStatus.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Tone.ofSlot(status).background,
                    border: Border.all(color: Tone.ofSlot(status).foreground),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(status.value),
              ],
            ),
        ],
      ),
    );
  }
}
