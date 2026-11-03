import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

mixin FormSubmit<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final serverErrors = ServerErrors();
  final _rejectedValues = <String, Object?>{};
  bool saving = false;
  String? submitError;

  FormFieldValidator<V> serverValidator<V>(String field, [FormFieldValidator<V>? local]) {
    final validate = serverErrors.validator(field, local);
    return (value) {
      if (serverErrors.of(field) != null && _rejectedValues.putIfAbsent(field, () => value) != value) {
        serverErrors.remove(field);
      }
      return validate(value);
    };
  }

  Future<void> submit(Future<void> Function() action) async {
    serverErrors.clear();
    _rejectedValues.clear();
    setState(() => submitError = null);
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (!mounted) return;
      submitError = serverErrors.apply(error);
      formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

void validateChangedFields(GlobalKey<FormState> formKey) {
  for (final field in formKey.currentState!.fields) {
    if (field.hasInteractedByUser) field.validate();
  }
}

class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.saving,
    required this.error,
    required this.onSave,
    required this.children,
    this.saveLabel = 'Save',
    this.width = 520,
    this.saveBlockedReason,
    this.extraActions = const [],
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final bool saving;
  final String? error;
  final VoidCallback onSave;
  final List<Widget> children;
  final String saveLabel;
  final double width;
  final String? saveBlockedReason;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final message = error;
    final blocked = saveBlockedReason;
    return AlertDialog(
      title: DialogTitle(title),
      content: SizedBox(
        width: width,
        child: Form(
          key: formKey,
          onChanged: () => validateChangedFields(formKey),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final child in children) ...[const SizedBox(height: 16), child],
                if (message != null) ...[const SizedBox(height: 12), FormError(message)],
              ],
            ),
          ),
        ),
      ),
      actions: [
        ...extraActions,
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        Tooltip(
          message: blocked ?? '',
          child: FilledButton(
            onPressed: saving || blocked != null ? null : onSave,
            child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(saveLabel),
          ),
        ),
      ],
    );
  }
}
