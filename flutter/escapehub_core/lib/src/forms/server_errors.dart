import 'package:flutter/widgets.dart';

import '../api/api_exception.dart';

class ServerErrors {
  final _fields = <String>{};
  Map<String, List<String>> _errors = const {};

  bool get isEmpty => _errors.isEmpty;

  String? apply(ApiException error) {
    _errors = error.fieldErrors;
    return _errors.keys.any(_fields.contains) ? null : error.message;
  }

  void clear() => _errors = const {};

  void remove(String field) => _errors = {..._errors}..remove(field);

  String? of(String field) => _errors[field]?.first;

  FormFieldValidator<T> validator<T>(String field, [FormFieldValidator<T>? local]) {
    _fields.add(field);
    return (value) => local?.call(value) ?? of(field);
  }
}
