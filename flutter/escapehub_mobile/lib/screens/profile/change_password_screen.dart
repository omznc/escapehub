import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/busy_button.dart';
import '../../widgets/form_message.dart';
import '../../widgets/password_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _serverErrors = ServerErrors();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    for (final controller in [_current, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    _serverErrors.clear();
    setState(() => _message = null);
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final message = await ref
          .read(sessionProvider.notifier)
          .changePassword(currentPassword: _current.text, newPassword: _password.text);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (error) {
      final message = _serverErrors.apply(error);
      if (!mounted) return;
      _form.currentState!.validate();
      setState(() => _message = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PasswordField(
              controller: _current,
              label: 'Current password',
              validator: _serverErrors.validator('currentPassword', Validators.required('Current password')),
              onChanged: (_) => _serverErrors.remove('currentPassword'),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: 'New password',
              validator: _serverErrors.validator('newPassword', Validators.password(label: 'New password')),
              onChanged: (_) => _serverErrors.remove('newPassword'),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmPassword,
              label: 'Confirm new password',
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _password.text),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FormMessage(_message),
            BusyButton(label: 'Change password', icon: Icons.lock_reset, busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
