import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../format.dart';
import '../../widgets/status_chip.dart';

class ScheduleGrid extends StatelessWidget {
  const ScheduleGrid({
    super.key,
    required this.week,
    required this.rooms,
    required this.schedules,
    required this.onOpen,
    required this.onAdd,
  });

  final DateTime week;
  final List<RoomListItemDto> rooms;
  final List<ScheduleDto> schedules;
  final ValueChanged<ScheduleDto> onOpen;
  final void Function(RoomListItemDto room, DateTime date) onAdd;

  @override
  Widget build(BuildContext context) {
    final days = [for (var offset = 0; offset < 7; offset++) addDays(week, offset)];
    final slots = <(int, DateTime), List<ScheduleDto>>{};
    for (final schedule in schedules) {
      slots.putIfAbsent((schedule.roomId, schedule.date), () => []).add(schedule);
    }
    final border = BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
    return SingleChildScrollView(
      child: Table(
        columnWidths: const {0: FixedColumnWidth(200)},
        defaultColumnWidth: const FlexColumnWidth(),
        border: TableBorder(horizontalInside: border, verticalInside: border),
        children: [
          TableRow(
            children: [
              const SizedBox.shrink(),
              for (final day in days) _DayHeader(day: day),
            ],
          ),
          for (final room in rooms)
            TableRow(
              children: [
                _RoomCell(room: room),
                for (final day in days)
                  _SlotCell(
                    slots: slots[(room.id, day)] ?? const [],
                    canAdd: room.isActive && !day.isBefore(today()),
                    onOpen: onOpen,
                    onAdd: () => onAdd(room, day),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = day == today();
    return Container(
      color: isToday ? theme.colorScheme.secondaryContainer : null,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(weekdayLabel(day), style: theme.textTheme.labelLarge),
          Text(formatDate(day), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RoomCell extends StatelessWidget {
  const _RoomCell({required this.room});

  final RoomListItemDto room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ApiImage(
            path: room.imageUrl,
            label: room.name,
            width: 36,
            height: 36,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(room.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({required this.slots, required this.canAdd, required this.onOpen, required this.onAdd});

  final List<ScheduleDto> slots;
  final bool canAdd;
  final ValueChanged<ScheduleDto> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final slot in slots) _SlotChip(slot: slot, onTap: () => onOpen(slot)),
          if (canAdd)
            IconButton(
              tooltip: 'Add a time slot on this day',
              visualDensity: VisualDensity.compact,
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
            ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.onTap});

  final ScheduleDto slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = Tone.ofSlot(slot.status);
    final client = slot.clientName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: client == null ? slot.status.value : '${slot.status.value}: $client',
        child: Material(
          color: tone.background,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                '${slot.startTime} to ${slot.endTime}',
                textAlign: TextAlign.center,
                style: TextStyle(color: tone.foreground, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
