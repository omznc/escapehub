import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/form_dialog.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> with FormSubmit {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _save() => submit(() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await ref
        .read(sessionProvider.notifier)
        .changePassword(currentPassword: _current.text, newPassword: _password.text);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Change password',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      saveLabel: 'Change password',
      width: 420,
      children: [
        TextFormField(
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
          validator: serverValidator('currentPassword', Validators.required('Current password')),
        ),
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password', helperText: 'Between 4 and 100 characters.'),
          validator: serverValidator('newPassword', Validators.password(label: 'New password')),
        ),
        TextFormField(
          controller: _confirm,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm the new password'),
          validator: Validators.combine([
            Validators.required('Password confirmation'),
            Validators.confirmPassword(() => _password.text),
          ]),
        ),
      ],
    );
  }
}
