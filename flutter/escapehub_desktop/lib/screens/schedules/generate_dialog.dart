import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/room_dropdown.dart';
import 'schedule_dialog.dart';

Future<DateTime?> showGenerateDialog(BuildContext context, {int? roomId}) => showDialog<DateTime>(
  context: context,
  builder: (_) => GenerateDialog(roomId: roomId),
);

class GenerateDialog extends ConsumerStatefulWidget {
  const GenerateDialog({super.key, this.roomId});

  final int? roomId;

  @override
  ConsumerState<GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends ConsumerState<GenerateDialog> with FormSubmit {
  late int? _roomId = widget.roomId;
  DateTime? _startDate = addDays(today(), 1);
  DateTime? _endDate = addDays(today(), 14);
  String? _dayStart = '10:00';
  String? _dayEnd = '22:00';
  final _duration = TextEditingController(text: '60');
  final _break = TextEditingController(text: '30');
  final _days = {...Weekday.values};

  @override
  void dispose() {
    _duration.dispose();
    _break.dispose();
    super.dispose();
  }

  void _selectRoom(int? roomId) {
    final rooms = ref.read(roomOptionsProvider).value ?? const <RoomListItemDto>[];
    final room = rooms.where((room) => room.id == roomId).firstOrNull;
    setState(() {
      _roomId = roomId;
      if (room != null) _duration.text = '${room.durationMinutes}';
    });
  }

  String? _endDateRule(DateTime? value) {
    final start = _startDate;
    if (value == null) return 'Select an end date.';
    if (start == null) return null;
    if (value.isBefore(start)) return 'The end date must be on or after the start date.';
    return value.isAfter(addDays(start, 92)) ? 'The date range can have at most 92 days.' : null;
  }

  void _generate() => submit(() async {
    final result = await ref
        .read(apiClientProvider)
        .schedules
        .generate(
          GenerateSchedulesRequest(
            roomId: _roomId!,
            startDate: _startDate!,
            endDate: _endDate!,
            startTime: _dayStart!,
            endTime: _dayEnd!,
            slotDurationMinutes: int.parse(_duration.text.trim()),
            breakMinutes: int.parse(_break.text.trim()),
            daysOfWeek: _days,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop(_startDate);
    showSuccessSnackBar(context, result.message);
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Generate time slots',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _generate,
      saveLabel: 'Generate',
      width: 620,
      children: [
        const Text(
          'Create time slots for each selected day in the date range. '
          'Slots that overlap an existing slot or start in the past are skipped.',
        ),
        RoomDropdown(
          value: _roomId,
          activeOnly: true,
          onChanged: _selectRoom,
          validator: serverValidator('roomId', Validators.selection<int>('a room')),
        ),
        FieldRow(
          children: [
            DateFormField(
              label: 'First day',
              initialValue: _startDate,
              firstDate: today(),
              onChanged: (value) => setState(() => _startDate = value),
              validator: serverValidator('startDate', Validators.selection<DateTime>('a start date')),
            ),
            DateFormField(
              label: 'Last day',
              initialValue: _endDate,
              firstDate: today(),
              onChanged: (value) => setState(() => _endDate = value),
              validator: serverValidator('endDate', _endDateRule),
            ),
          ],
        ),
        FieldRow(
          children: [
            TimeFormField(
              label: 'Daily start time',
              initialValue: _dayStart,
              onChanged: (value) => setState(() => _dayStart = value),
              validator: serverValidator('startTime', Validators.time('Daily start time')),
            ),
            TimeFormField(
              label: 'Daily end time',
              initialValue: _dayEnd,
              onChanged: (value) => setState(() => _dayEnd = value),
              validator: serverValidator(
                'endTime',
                (value) => Validators.time('Daily end time')(value) ?? timeAfter(_dayStart, value),
              ),
            ),
          ],
        ),
        FieldRow(
          children: [
            TextFormField(
              controller: _duration,
              decoration: const InputDecoration(labelText: 'Slot length in minutes', helperText: 'From 15 to 480.'),
              validator: serverValidator('slotDurationMinutes', Validators.intRange('Slot length', min: 15, max: 480)),
            ),
            TextFormField(
              controller: _break,
              decoration: const InputDecoration(
                labelText: 'Break between slots in minutes',
                helperText: 'From 0 to 240.',
              ),
              validator: serverValidator('breakMinutes', Validators.intRange('Break', min: 0, max: 240)),
            ),
          ],
        ),
        _DaysField(
          days: _days,
          onChanged: (day, selected) => setState(() => selected ? _days.add(day) : _days.remove(day)),
          validator: serverValidator('daysOfWeek'),
        ),
      ],
    );
  }
}

class _DaysField extends StatelessWidget {
  const _DaysField({required this.days, required this.onChanged, required this.validator});

  final Set<Weekday> days;
  final void Function(Weekday day, bool selected) onChanged;
  final FormFieldValidator<Set<Weekday>> validator;

  @override
  Widget build(BuildContext context) {
    return FormField<Set<Weekday>>(
      initialValue: {...days},
      validator: (value) => days.isEmpty ? 'Select at least one day of the week.' : validator(value),
      builder: (field) => InputDecorator(
        decoration: InputDecoration(labelText: 'Days of the week', errorText: field.errorText),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in Weekday.values)
              FilterChip(
                label: Text(day.value.substring(0, 3)),
                selected: days.contains(day),
                onSelected: (selected) {
                  onChanged(day, selected);
                  field.didChange({...days});
                },
              ),
          ],
        ),
      ),
    );
  }
}
