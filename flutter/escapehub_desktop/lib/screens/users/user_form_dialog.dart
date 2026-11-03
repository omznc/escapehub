import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pages.dart';

Future<UserDto?> showUserForm(BuildContext context, [UserDto? user]) => showDialog<UserDto>(
  context: context,
  builder: (_) => UserFormDialog(user: user),
);

class UserFormDialog extends ConsumerStatefulWidget {
  const UserFormDialog({super.key, this.user});

  final UserDto? user;

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> with FormSubmit {
  late final _username = TextEditingController(text: widget.user?.username);
  late final _firstName = TextEditingController(text: widget.user?.firstName);
  late final _lastName = TextEditingController(text: widget.user?.lastName);
  late final _email = TextEditingController(text: widget.user?.email);
  late final _phone = TextEditingController(text: widget.user?.phone);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late int? _cityId = widget.user?.cityId;
  late String? _role = widget.user?.role;
  late bool _changePassword = widget.user == null;

  bool get _isNew => widget.user == null;

  bool get _isOwnAccount => widget.user?.id == ref.read(currentUserProvider)?.id;

  @override
  void dispose() {
    for (final controller in [_username, _firstName, _lastName, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<UserDto> _create(UsersApi api) => api.create(
    CreateUserRequest(
      username: _username.text.trim(),
      password: _password.text,
      email: _email.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: optionalText(_phone.text),
      cityId: _cityId,
      role: _role!,
    ),
  );

  Future<UserDto> _update(UsersApi api, int id) async {
    final saved = await api.update(
      id,
      UpdateUserRequest(
        email: _email.text.trim(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: optionalText(_phone.text),
        cityId: _cityId,
        role: _role!,
      ),
    );
    if (_changePassword) await api.resetPassword(id, _password.text);
    return saved;
  }

  void _save() => submit(() async {
    final api = ref.read(apiClientProvider).users;
    final user = widget.user;
    final saved = user == null ? await _create(api) : await _update(api, user.id);
    ref.invalidate(managerOptionsProvider);
    if (!mounted) return;
    Navigator.of(context).pop(saved);
    final action = user == null ? 'created' : 'saved';
    showSuccessSnackBar(context, 'The user ${saved.username} was $action.');
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isNew ? 'New user' : 'Edit user',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      width: 620,
      children: [
        if (_isNew)
          TextFormField(
            controller: _username,
            decoration: const InputDecoration(
              labelText: 'Username',
              helperText: '3 to 50 characters: letters, digits, dots, dashes and underscores.',
            ),
            validator: serverValidator('username', Validators.username()),
          )
        else
          InfoRow(icon: Icons.person_outline, label: 'Username', value: widget.user!.username),
        FieldRow(
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: serverValidator(
                'firstName',
                Validators.combine([Validators.required('First name'), Validators.maxLength('First name', 100)]),
              ),
            ),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: serverValidator(
                'lastName',
                Validators.combine([Validators.required('Last name'), Validators.maxLength('Last name', 100)]),
              ),
            ),
          ],
        ),
        FieldRow(
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email', helperText: 'Format: name@example.com'),
              validator: serverValidator('email', Validators.email()),
            ),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone', helperText: 'Optional. Format: +387 61 234 567'),
              validator: serverValidator('phone', Validators.phone()),
            ),
          ],
        ),
        FieldRow(
          children: [
            ReferenceDropdown(
              table: ReferenceTable.cities,
              label: 'City',
              value: _cityId,
              emptyLabel: 'No city',
              canAdd: true,
              onChanged: (value) => setState(() => _cityId = value),
              validator: serverValidator('cityId'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              validator: serverValidator('role', Validators.selection<String>('a role')),
              onChanged: (value) => setState(() => _role = value),
              items: [for (final role in Roles.staff) DropdownMenuItem(value: role, child: Text(roleLabel(role)))],
            ),
          ],
        ),
        if (_isOwnAccount)
          const InfoRow(
            icon: Icons.password,
            label: 'Password',
            value: 'To change your own password, open your account menu and select Change password.',
          )
        else if (!_isNew)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Change password'),
            subtitle: const Text('Set a new password for this user. The old password is not necessary.'),
            value: _changePassword,
            onChanged: (value) => setState(() => _changePassword = value),
          ),
        if (_changePassword) _passwordFields(),
      ],
    );
  }

  Widget _passwordFields() {
    final field = _isNew ? 'password' : 'newPassword';
    final label = _isNew ? 'Password' : 'New password';
    return FieldRow(
      children: [
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(labelText: label, helperText: 'Between 4 and 100 characters.'),
          validator: serverValidator(field, Validators.password(label: label)),
        ),
        TextFormField(
          controller: _confirm,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Confirm the ${label.toLowerCase()}'),
          validator: Validators.combine([
            Validators.required('Password confirmation'),
            Validators.confirmPassword(() => _password.text),
          ]),
        ),
      ],
    );
  }
}
