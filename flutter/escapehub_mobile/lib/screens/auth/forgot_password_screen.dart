import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/busy_button.dart';
import '../../widgets/form_message.dart';
import '../../widgets/password_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _serverErrors = ServerErrors();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _info;
  String? _message;

  @override
  void dispose() {
    for (final controller in [_email, _code, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    _serverErrors.clear();
    setState(() => _message = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (error) {
      final message = _serverErrors.apply(error);
      if (!mounted) return;
      _form.currentState!.validate();
      setState(() => _message = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
    final info = await ref.read(apiClientProvider).auth.forgotPassword(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _codeSent = true;
      _info = info;
    });
  });

  Future<void> _reset() => _run(() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final message = await ref
        .read(apiClientProvider)
        .auth
        .resetPassword(email: _email.text.trim(), code: _code.text.trim(), newPassword: _password.text);
    messenger.showSnackBar(SnackBar(content: Text(message)));
    navigator.pop();
  });

  void _changeEmail() => setState(() {
    _codeSent = false;
    _info = null;
    _code.clear();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _codeSent
                    ? 'Enter the 6-digit code from the email and choose a new password.'
                    : 'Enter the email of your account. We will send you a code to reset the password.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: _serverErrors.validator('email', Validators.email()),
                onChanged: (_) => _serverErrors.remove('email'),
              ),
              if (_codeSent) ..._resetFields(),
              const SizedBox(height: 24),
              FormMessage(_message),
              _codeSent
                  ? BusyButton(label: 'Reset password', icon: Icons.lock_reset, busy: _busy, onPressed: _reset)
                  : BusyButton(label: 'Send code', icon: Icons.send_outlined, busy: _busy, onPressed: _sendCode),
              if (_codeSent)
                TextButton(onPressed: _busy ? null : _changeEmail, child: const Text('Use a different email')),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _resetFields() {
    final info = _info;
    return [
      if (info != null) ...[
        const SizedBox(height: 12),
        Text(info, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
      const SizedBox(height: 16),
      TextFormField(
        controller: _code,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: const InputDecoration(
          labelText: 'Code from the email',
          helperText: 'Format: 6 digits, for example 123456',
          prefixIcon: Icon(Icons.pin_outlined),
        ),
        validator: _serverErrors.validator('code', Validators.resetCode()),
        onChanged: (_) => _serverErrors.remove('code'),
      ),
      const SizedBox(height: 8),
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
      ),
    ];
  }
}
