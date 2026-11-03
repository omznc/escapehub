import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/brand_header.dart';
import '../../widgets/busy_button.dart';
import '../../widgets/form_message.dart';
import '../../widgets/password_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _serverErrors = ServerErrors();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _serverErrors.clear();
    setState(() => _message = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).login(_username.text.trim(), _password.text);
    } on ApiException catch (error) {
      final message = _serverErrors.apply(error);
      if (!mounted) return;
      _form.currentState!.validate();
      setState(() => _message = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                    validator: _serverErrors.validator('username', Validators.required('Username')),
                    onChanged: (_) => _serverErrors.remove('username'),
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _password,
                    label: 'Password',
                    textInputAction: TextInputAction.done,
                    validator: _serverErrors.validator('password', Validators.required('Password')),
                    onChanged: (_) => _serverErrors.remove('password'),
                    onSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _open(const ForgotPasswordScreen()),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FormMessage(_message),
                  BusyButton(label: 'Sign in', icon: Icons.login, busy: _busy, onPressed: _submit),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New to EscapeHub?'),
                      TextButton(
                        onPressed: () => _open(const RegisterScreen()),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
