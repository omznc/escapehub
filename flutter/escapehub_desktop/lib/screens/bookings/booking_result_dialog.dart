import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';

enum ResultMode {
  complete(
    BookingAction.complete,
    'Complete the booking',
    'Complete',
    'The booking was completed and the result was saved.',
  ),
  record(BookingAction.recordResult, 'Record the result', 'Save result', 'The result was saved.'),
  edit(BookingAction.editResult, 'Edit the result', 'Save result', 'The result was changed.');

  const ResultMode(this.action, this.title, this.saveLabel, this.success);

  final BookingAction action;
  final String title;
  final String saveLabel;
  final String success;
}

Future<BookingDto?> showResultDialog(BuildContext context, BookingDto booking, ResultMode mode) =>
    showDialog<BookingDto>(
      context: context,
      builder: (_) => BookingResultDialog(booking: booking, mode: mode),
    );

class BookingResultDialog extends ConsumerStatefulWidget {
  const BookingResultDialog({super.key, required this.booking, required this.mode});

  final BookingDto booking;
  final ResultMode mode;

  @override
  ConsumerState<BookingResultDialog> createState() => _BookingResultDialogState();
}

class _BookingResultDialogState extends ConsumerState<BookingResultDialog> with FormSubmit {
  late final RoomResultDto? _result = widget.booking.result;
  late bool _escaped = _result?.escaped ?? true;
  late final _time = TextEditingController(text: _text(_result?.completionTimeMinutes));
  late final _hints = TextEditingController(text: _text(_result?.hintsUsed));
  late final _score = TextEditingController(text: _text(_result?.score));
  late final _notes = TextEditingController(text: _result?.managerNotes);

  static String _text(int? value) => value == null ? '' : '$value';

  String _field(String name) => widget.mode == ResultMode.complete ? 'result.$name' : name;

  @override
  void dispose() {
    _time.dispose();
    _hints.dispose();
    _score.dispose();
    _notes.dispose();
    super.dispose();
  }

  SaveRoomResultRequest _request() => SaveRoomResultRequest(
    escaped: _escaped,
    completionTimeMinutes: int.tryParse(_time.text.trim()),
    hintsUsed: int.tryParse(_hints.text.trim()),
    score: int.tryParse(_score.text.trim()),
    managerNotes: optionalText(_notes.text),
  );

  Future<BookingDto> _send() {
    final api = ref.read(apiClientProvider).bookings;
    final id = widget.booking.id;
    return switch (widget.mode) {
      ResultMode.complete => api.complete(id, _request()),
      ResultMode.record => api.recordResult(id, _request()),
      ResultMode.edit => api.editResult(id, _request()),
    };
  }

  void _save() => submit(() async {
    final saved = await _send();
    if (!mounted) return;
    Navigator.of(context).pop(saved);
    showSuccessSnackBar(context, widget.mode.success);
  });

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return FormDialog(
      title: widget.mode.title,
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      saveLabel: widget.mode.saveLabel,
      children: [
        Text('${booking.roomName}, ${formatDate(booking.date)} at ${booking.startTime}, ${booking.clientName}'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('The team escaped'),
          value: _escaped,
          onChanged: (value) => setState(() => _escaped = value),
        ),
        FieldRow(
          children: [
            TextFormField(
              controller: _time,
              decoration: const InputDecoration(
                labelText: 'Time in minutes',
                helperText: 'Optional, 1 to 480.',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              validator: serverValidator(
                _field('completionTimeMinutes'),
                Validators.intRange('Time', min: 1, max: 480, required: false),
              ),
            ),
            TextFormField(
              controller: _hints,
              decoration: const InputDecoration(
                labelText: 'Hints used',
                helperText: 'Optional, 0 to 50.',
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
              validator: serverValidator(
                _field('hintsUsed'),
                Validators.intRange('Hints used', min: 0, max: 50, required: false),
              ),
            ),
            TextFormField(
              controller: _score,
              decoration: const InputDecoration(
                labelText: 'Score',
                helperText: 'Optional, 0 to 100.',
                prefixIcon: Icon(Icons.emoji_events_outlined),
              ),
              validator: serverValidator(
                _field('score'),
                Validators.intRange('Score', min: 0, max: 100, required: false),
              ),
            ),
          ],
        ),
        TextFormField(
          controller: _notes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Manager notes',
            helperText: 'Optional, at most 2000 characters.',
          ),
          validator: serverValidator(_field('managerNotes'), Validators.maxLength('Manager notes', 2000)),
        ),
      ],
    );
  }
}
