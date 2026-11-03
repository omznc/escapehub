import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/actions.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pages.dart';
import '../../widgets/room_dropdown.dart';
import '../../widgets/status_chip.dart';

Future<DateTime?> showScheduleDialog(BuildContext context, {ScheduleDto? schedule, int? roomId, DateTime? date}) =>
    showDialog<DateTime>(
      context: context,
      builder: (_) => ScheduleDialog(schedule: schedule, roomId: roomId, date: date),
    );

String? timeAfter(String? start, String? end) {
  if (start == null || end == null) return null;
  return end.compareTo(start) <= 0 ? 'The end time must be after the start time ($start).' : null;
}

class ScheduleDialog extends ConsumerStatefulWidget {
  const ScheduleDialog({super.key, this.schedule, this.roomId, this.date});

  final ScheduleDto? schedule;
  final int? roomId;
  final DateTime? date;

  @override
  ConsumerState<ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends ConsumerState<ScheduleDialog> with FormSubmit {
  late int? _roomId = widget.schedule?.roomId ?? widget.roomId;
  late DateTime? _date = widget.schedule?.date ?? widget.date;
  late String? _start = widget.schedule?.startTime;
  late String? _end = widget.schedule?.endTime;
  late bool _isBlocked = widget.schedule?.isBlocked ?? false;

  String? get _lockedReason {
    final schedule = widget.schedule;
    if (schedule == null) return null;
    if (schedule.status == SlotStatus.past || schedule.date.isBefore(today())) {
      return 'This time slot is in the past. You cannot change it.';
    }
    if (schedule.status == SlotStatus.booked) {
      return 'This time slot has an active booking. Cancel the booking before you change the slot.';
    }
    return null;
  }

  ScheduleRequest _request() =>
      ScheduleRequest(roomId: _roomId!, date: _date!, startTime: _start!, endTime: _end!, isBlocked: _isBlocked);

  void _save() => submit(() async {
    final api = ref.read(apiClientProvider).schedules;
    final schedule = widget.schedule;
    final saved = schedule == null ? await api.create(_request()) : await api.update(schedule.id, _request());
    if (!mounted) return;
    Navigator.of(context).pop(saved.date);
    final action = schedule == null ? 'created' : 'saved';
    showSuccessSnackBar(
      context,
      'The time slot ${saved.startTime} to ${saved.endTime} on ${formatDate(saved.date)} in ${saved.roomName} was $action.',
    );
  });

  Future<void> _delete(ScheduleDto schedule) async {
    final deleted = await confirmAndRun(
      context,
      title: 'Delete the time slot',
      message:
          'Do you want to delete the time slot ${schedule.startTime} to ${schedule.endTime} '
          'on ${formatDate(schedule.date)} in ${schedule.roomName}?',
      confirmLabel: 'Delete',
      destructive: true,
      action: () => ref.read(apiClientProvider).schedules.delete(schedule.id),
      success: 'The time slot was deleted.',
    );
    if (deleted && mounted) Navigator.of(context).pop(schedule.date);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final locked = _lockedReason;
    return FormDialog(
      title: schedule == null ? 'New time slot' : 'Time slot',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      saveBlockedReason: locked,
      extraActions: [
        if (schedule != null)
          Tooltip(
            message: schedule.deleteBlockedReason ?? 'Delete the time slot',
            child: TextButton.icon(
              onPressed: schedule.canDelete ? () => _delete(schedule) : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ),
      ],
      children: [
        if (schedule != null) _ScheduleSummary(schedule: schedule),
        if (locked != null) Text(locked, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        RoomDropdown(
          value: _roomId,
          activeOnly: schedule == null,
          enabled: schedule == null,
          onChanged: (value) => setState(() => _roomId = value),
          validator: serverValidator('roomId', Validators.selection<int>('a room')),
        ),
        DateFormField(
          label: 'Date',
          initialValue: _date,
          firstDate: schedule == null ? today() : null,
          onChanged: (value) => setState(() => _date = value),
          validator: serverValidator('date', Validators.selection<DateTime>('a date')),
        ),
        FieldRow(
          children: [
            TimeFormField(
              label: 'Start time',
              initialValue: _start,
              onChanged: (value) => setState(() => _start = value),
              validator: serverValidator('startTime', Validators.time('Start time')),
            ),
            TimeFormField(
              label: 'End time',
              initialValue: _end,
              onChanged: (value) => setState(() => _end = value),
              validator: serverValidator(
                'endTime',
                (value) => Validators.time('End time')(value) ?? timeAfter(_start, value),
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Blocked'),
          subtitle: const Text('Clients cannot book a blocked time slot.'),
          value: _isBlocked,
          onChanged: locked == null ? (value) => setState(() => _isBlocked = value) : null,
        ),
      ],
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({required this.schedule});

  final ScheduleDto schedule;

  @override
  Widget build(BuildContext context) {
    final client = schedule.clientName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip(schedule.status.value, Tone.ofSlot(schedule.status)),
        if (client != null)
          InfoRow(
            icon: Icons.person_outline,
            label: 'Booked by',
            value: '$client (${schedule.bookingStatus ?? 'booking'})',
          ),
      ],
    );
  }
}
