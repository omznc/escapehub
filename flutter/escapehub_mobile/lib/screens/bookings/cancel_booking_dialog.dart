import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';

Future<String?> showCancelBookingDialog(BuildContext context, BookingDto booking) => showDialog<String>(
  context: context,
  builder: (context) => _CancelBookingDialog(booking: booking),
);

class _CancelBookingDialog extends StatefulWidget {
  const _CancelBookingDialog({required this.booking});

  final BookingDto booking;

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) Navigator.of(context).pop(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const DialogTitle('Cancel booking'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel ${booking.roomName} on ${formatDay(booking.date)} at ${booking.startTime}?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reason,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Reason', helperText: '3-500 characters'),
              validator: Validators.lengthBetween('Reason', 3, 500),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Keep booking')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: _submit,
          child: const Text('Cancel booking'),
        ),
      ],
    );
  }
}
