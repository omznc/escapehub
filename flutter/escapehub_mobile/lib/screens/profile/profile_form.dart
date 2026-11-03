import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/account_field.dart';
import '../../widgets/busy_button.dart';
import '../../widgets/form_message.dart';

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, required this.user});

  final UserDto user;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _form = GlobalKey<FormState>();
  final _serverErrors = ServerErrors();
  late final _firstName = TextEditingController(text: widget.user.firstName);
  late final _lastName = TextEditingController(text: widget.user.lastName);
  late final _email = TextEditingController(text: widget.user.email);
  late final _phone = TextEditingController(text: widget.user.phone);
  late int? _cityId = widget.user.cityId;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  UpdateProfileRequest _request() {
    final phone = _phone.text.trim();
    return UpdateProfileRequest(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: phone.isEmpty ? null : phone,
      cityId: _cityId,
    );
  }

  Future<void> _save() async {
    _serverErrors.clear();
    setState(() => _message = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).updateProfile(_request());
      if (mounted) showSuccessSnackBar(context, 'Your profile details were saved.');
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
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Personal details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          AccountField.name(
            controller: _firstName,
            serverErrors: _serverErrors,
            field: 'firstName',
            label: 'First name',
          ),
          AccountField.name(controller: _lastName, serverErrors: _serverErrors, field: 'lastName', label: 'Last name'),
          AccountField.email(controller: _email, serverErrors: _serverErrors),
          AccountField.phone(controller: _phone, serverErrors: _serverErrors),
          _CityField(
            cityId: _cityId,
            validator: _serverErrors.validator<int?>('cityId'),
            onChanged: (id) => setState(() => _cityId = id),
          ),
          const SizedBox(height: 16),
          FormMessage(_message),
          BusyButton(label: 'Save changes', icon: Icons.save_outlined, busy: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

class _CityField extends ConsumerWidget {
  const _CityField({required this.cityId, required this.validator, required this.onChanged});

  final int? cityId;
  final FormFieldValidator<int?> validator;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(referenceProvider(ReferenceTable.cities))
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('$error'),
          data: (items) {
            final cities = items.cast<CityDto>();
            final country = cities.where((city) => city.id == cityId).firstOrNull?.countryName;
            return DropdownButtonFormField<int?>(
              initialValue: cityId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'City (optional)',
                prefixIcon: const Icon(Icons.location_city_outlined),
                helperText: country == null ? 'Select a city to show the country.' : 'Country: $country',
              ),
              items: [
                const DropdownMenuItem(child: Text('No city')),
                for (final city in cities) DropdownMenuItem(value: city.id, child: Text(city.name)),
              ],
              validator: validator,
              onChanged: onChanged,
            );
          },
        );
  }
}
