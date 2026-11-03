import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

class AccountField extends StatelessWidget {
  const AccountField({
    super.key,
    required this.controller,
    required this.serverErrors,
    required this.field,
    required this.label,
    required this.icon,
    required this.validator,
    this.textInputAction,
    this.keyboardType,
    this.helperText,
  });

  AccountField.name({
    super.key,
    required this.controller,
    required this.serverErrors,
    required this.field,
    required this.label,
    this.textInputAction,
  }) : icon = Icons.badge_outlined,
       validator = Validators.combine([Validators.required(label), Validators.maxLength(label, 100)]),
       keyboardType = TextInputType.name,
       helperText = null;

  AccountField.email({super.key, required this.controller, required this.serverErrors, this.textInputAction})
    : field = 'email',
      label = 'Email',
      icon = Icons.email_outlined,
      validator = Validators.email(),
      keyboardType = TextInputType.emailAddress,
      helperText = null;

  AccountField.phone({super.key, required this.controller, required this.serverErrors, this.textInputAction})
    : field = 'phone',
      label = 'Phone (optional)',
      icon = Icons.phone_outlined,
      validator = Validators.phone(),
      keyboardType = TextInputType.phone,
      helperText = 'Format: +387 61 234 567';

  final TextEditingController controller;
  final ServerErrors serverErrors;
  final String field;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(labelText: label, helperText: helperText, prefixIcon: Icon(icon)),
        validator: serverErrors.validator(field, validator),
        onChanged: (_) => serverErrors.remove(field),
      ),
    );
  }
}
