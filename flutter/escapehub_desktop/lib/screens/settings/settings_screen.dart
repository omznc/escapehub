import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pages.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<SettingsDto> _settings = _load();

  Future<SettingsDto> _load() => ref.read(apiClientProvider).settings.get();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureView<SettingsDto>(
        future: _settings,
        onRetry: () => setState(() => _settings = _load()),
        builder: (context, settings) => _SettingsForm(settings: settings),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final SettingsDto settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> with FormSubmit {
  late SettingsDto _saved = widget.settings;
  late final _company = TextEditingController(text: _saved.companyName);
  late final _email = TextEditingController(text: _saved.contactEmail);
  late final _phone = TextEditingController(text: _saved.contactPhone);
  late final _pointsPerPlayer = TextEditingController(text: '${_saved.pointsPerPlayer}');
  late final _pointsPerUnit = TextEditingController(text: formatNumber(_saved.pointsPerCurrencyUnit));
  late final _deadline = TextEditingController(text: '${_saved.cancellationDeadlineHours}');
  late final _reminder = TextEditingController(text: '${_saved.reminderHoursBefore}');

  @override
  void dispose() {
    for (final controller in [_company, _email, _phone, _pointsPerPlayer, _pointsPerUnit, _deadline, _reminder]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() => submit(() async {
    final saved = await ref
        .read(apiClientProvider)
        .settings
        .update(
          UpdateSettingsRequest(
            companyName: _company.text.trim(),
            contactEmail: _email.text.trim(),
            contactPhone: optionalText(_phone.text),
            pointsPerPlayer: int.parse(_pointsPerPlayer.text.trim()),
            pointsPerCurrencyUnit: parseDecimal(_pointsPerUnit.text)!,
            cancellationDeadlineHours: int.parse(_deadline.text.trim()),
            reminderHoursBefore: int.parse(_reminder.text.trim()),
          ),
        );
    if (!mounted) return;
    setState(() => _saved = saved);
    showSuccessSnackBar(context, 'The system settings were saved.');
  });

  @override
  Widget build(BuildContext context) {
    final message = submitError;
    return Form(
      key: formKey,
      onChanged: () => validateChangedFields(formKey),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _companySection(),
                  const SizedBox(height: 16),
                  _loyaltySection(),
                  const SizedBox(height: 16),
                  _bookingSection(),
                  if (message != null) ...[const SizedBox(height: 12), FormError(message)],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        _lastChanged(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lastChanged() {
    final changed = 'Last changed on ${formatTimestamp(_saved.updatedAt)}';
    final name = _saved.updatedByName;
    return name == null ? changed : '$changed by $name';
  }

  Widget _companySection() {
    return SectionCard(
      title: 'Company',
      child: Column(
        children: [
          TextFormField(
            controller: _company,
            decoration: const InputDecoration(labelText: 'Company name', helperText: 'At most 200 characters.'),
            validator: serverValidator(
              'companyName',
              Validators.combine([Validators.required('Company name'), Validators.maxLength('Company name', 200)]),
            ),
          ),
          const SizedBox(height: 16),
          FieldRow(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Contact email', helperText: 'Format: name@example.com'),
                validator: serverValidator('contactEmail', Validators.email()),
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Contact phone',
                  helperText: 'Optional. Format: +387 61 234 567',
                ),
                validator: serverValidator('contactPhone', Validators.phone()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loyaltySection() {
    return SectionCard(
      title: 'Loyalty earning rules',
      child: FieldRow(
        children: [
          TextFormField(
            controller: _pointsPerPlayer,
            decoration: const InputDecoration(
              labelText: 'Points for each player',
              helperText: 'A whole number from 0 to 1000.',
            ),
            validator: serverValidator(
              'pointsPerPlayer',
              Validators.intRange('Points for each player', min: 0, max: 1000),
            ),
          ),
          TextFormField(
            controller: _pointsPerUnit,
            decoration: const InputDecoration(
              labelText: 'Points for each KM paid',
              helperText: 'A number from 0 to 100, for example 0.5.',
            ),
            validator: serverValidator(
              'pointsPerCurrencyUnit',
              Validators.decimalRange('Points for each KM paid', min: 0, max: 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingSection() {
    return SectionCard(
      title: 'Bookings and reminders',
      child: FieldRow(
        children: [
          TextFormField(
            controller: _deadline,
            decoration: const InputDecoration(
              labelText: 'Cancellation deadline in hours',
              helperText: 'Clients can cancel until this many hours before the session. From 0 to 168.',
              helperMaxLines: 2,
            ),
            validator: serverValidator(
              'cancellationDeadlineHours',
              Validators.intRange('Cancellation deadline', min: 0, max: 168),
            ),
          ),
          TextFormField(
            controller: _reminder,
            decoration: const InputDecoration(
              labelText: 'Reminder in hours before the session',
              helperText: 'From 1 to 168.',
            ),
            validator: serverValidator('reminderHoursBefore', Validators.intRange('Reminder time', min: 1, max: 168)),
          ),
        ],
      ),
    );
  }
}
