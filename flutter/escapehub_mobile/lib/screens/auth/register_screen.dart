import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/account_field.dart';
import '../../widgets/busy_button.dart';
import '../../widgets/form_message.dart';
import '../../widgets/password_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _serverErrors = ServerErrors();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _username, _email, _phone, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  RegisterRequest _request() {
    final phone = _phone.text.trim();
    return RegisterRequest(
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: phone.isEmpty ? null : phone,
    );
  }

  Future<void> _submit() async {
    _serverErrors.clear();
    setState(() => _message = null);
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final request = _request();
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).register(request);
      messenger.showSnackBar(
        SnackBar(content: Text('Welcome, ${request.firstName}. Your EscapeHub account was created.')),
      );
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
      appBar: AppBar(title: const Text('Create an account')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AccountField.name(
                controller: _firstName,
                serverErrors: _serverErrors,
                field: 'firstName',
                label: 'First name',
                textInputAction: TextInputAction.next,
              ),
              AccountField.name(
                controller: _lastName,
                serverErrors: _serverErrors,
                field: 'lastName',
                label: 'Last name',
                textInputAction: TextInputAction.next,
              ),
              AccountField(
                controller: _username,
                serverErrors: _serverErrors,
                field: 'username',
                label: 'Username',
                icon: Icons.person_outline,
                validator: Validators.username(),
                textInputAction: TextInputAction.next,
                helperText: '3-50 characters: letters, digits, ".", "-" or "_"',
              ),
              AccountField.email(
                controller: _email,
                serverErrors: _serverErrors,
                textInputAction: TextInputAction.next,
              ),
              AccountField.phone(
                controller: _phone,
                serverErrors: _serverErrors,
                textInputAction: TextInputAction.next,
              ),
              PasswordField(
                controller: _password,
                label: 'Password',
                validator: _serverErrors.validator('password', Validators.password()),
                onChanged: (_) => _serverErrors.remove('password'),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmPassword,
                label: 'Confirm password',
                textInputAction: TextInputAction.done,
                validator: Validators.confirmPassword(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FormMessage(_message),
              BusyButton(label: 'Create account', icon: Icons.person_add_alt, busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
