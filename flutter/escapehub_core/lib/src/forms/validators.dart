import 'package:flutter/widgets.dart';

double? parseDecimal(String value) => double.tryParse(value.trim().replaceAll(',', '.'));

abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phonePattern = RegExp(r'^\+?[0-9][0-9 /-]{5,18}[0-9]$');
  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9._-]+$');
  static final _codePattern = RegExp(r'^[0-9]{6}$');
  static final _timePattern = RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$');

  static FormFieldValidator<String> combine(List<FormFieldValidator<String>> validators) =>
      (value) => validators.map((validator) => validator(value)).nonNulls.firstOrNull;

  static FormFieldValidator<String> required(String label) =>
      (value) => _isBlank(value) ? '$label is required.' : null;

  static FormFieldValidator<T> selection<T>(String label) =>
      (value) => value == null ? 'Select $label.' : null;

  static FormFieldValidator<String> maxLength(String label, int max) =>
      (value) => (value?.trim().length ?? 0) > max ? '$label can have at most $max characters.' : null;

  static FormFieldValidator<String> lengthBetween(String label, int min, int max) => (value) {
    final length = value?.trim().length ?? 0;
    return length < min || length > max ? '$label must have between $min and $max characters.' : null;
  };

  static FormFieldValidator<String> email({bool required = true}) => (value) {
    if (_isBlank(value)) return required ? 'Email is required.' : null;
    return _emailPattern.hasMatch(value!.trim()) ? null : 'Enter a valid email, for example name@example.com.';
  };

  static FormFieldValidator<String> phone({bool required = false}) => (value) {
    if (_isBlank(value)) return required ? 'Phone number is required.' : null;
    return _phonePattern.hasMatch(value!.trim()) ? null : 'Enter a phone number in the format +387 61 234 567.';
  };

  static FormFieldValidator<String> username() => (value) {
    if (_isBlank(value)) return 'Username is required.';
    final text = value!.trim();
    if (text.length < 3 || text.length > 50) return 'Username must have between 3 and 50 characters.';
    return _usernamePattern.hasMatch(text)
        ? null
        : 'Username can contain only letters, digits, dots, dashes and underscores, for example john.doe.';
  };

  static FormFieldValidator<String> password({String label = 'Password'}) => (value) {
    if (value == null || value.isEmpty) return '$label is required.';
    return value.length < 4 || value.length > 100 ? '$label must have between 4 and 100 characters.' : null;
  };

  static FormFieldValidator<String> confirmPassword(String Function() password) =>
      (value) => value == password() ? null : 'The passwords do not match. Enter the same password again.';

  static FormFieldValidator<String> resetCode() =>
      (value) => _codePattern.hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter the 6-digit code from the email, for example 123456.';

  static FormFieldValidator<String> time(String label) => (value) {
    if (_isBlank(value)) return '$label is required.';
    return _timePattern.hasMatch(value!.trim()) ? null : 'Enter the time in the format HH:mm, for example 18:30.';
  };

  static FormFieldValidator<String> intRange(
    String label, {
    required int min,
    required int max,
    bool required = true,
  }) => (value) {
    if (_isBlank(value)) return required ? '$label is required.' : null;
    final number = int.tryParse(value!.trim());
    return number == null || number < min || number > max
        ? '$label must be a whole number between $min and $max.'
        : null;
  };

  static FormFieldValidator<String> decimalRange(
    String label, {
    required double min,
    required double max,
    bool required = true,
  }) => (value) {
    if (_isBlank(value)) return required ? '$label is required.' : null;
    final number = parseDecimal(value!);
    return number == null || number < min || number > max
        ? '$label must be a number between ${_plain(min)} and ${_plain(max)}, for example 25.50.'
        : null;
  };

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  static String _plain(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
}
