import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) => showDialog<String>(
  context: context,
  builder: (context) => _ReasonDialog(title: title, message: message, confirmLabel: confirmLabel),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.message, required this.confirmLabel});

  final String title;
  final String message;
  final String confirmLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_form.currentState!.validate()) Navigator.of(context).pop(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: DialogTitle(widget.title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.message),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reason,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Reason', helperText: 'Between 3 and 500 characters.'),
                validator: Validators.combine([
                  Validators.required('Reason'),
                  Validators.lengthBetween('Reason', 3, 500),
                ]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
