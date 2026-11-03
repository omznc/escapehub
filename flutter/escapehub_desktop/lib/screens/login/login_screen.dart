import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/form_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with FormSubmit {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() => submit(() => ref.read(sessionProvider.notifier).desktopLogin(_username.text.trim(), _password.text));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = submitError;
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: formKey,
                onChanged: () => validateChangedFields(formKey),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_person_outlined, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('EscapeHub Staff', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in with an administrator or room manager account.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _username,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                      validator: serverValidator('username', Validators.required('Username')),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      onFieldSubmitted: (_) => _login(),
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      validator: serverValidator('password', Validators.required('Password')),
                    ),
                    if (message != null) ...[const SizedBox(height: 16), FormError(message)],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: saving ? null : _login,
                      child: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
