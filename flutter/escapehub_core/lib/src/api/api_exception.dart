import 'dart:convert';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) return ApiException(_transportMessage(error));
    final body = _body(response.data);
    return ApiException(
      body?['message'] as String? ?? 'The server returned the status ${response.statusCode}.',
      statusCode: response.statusCode,
      fieldErrors: _fieldErrors(body?['errors']),
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;

  static String _transportMessage(DioException error) {
    final url = error.requestOptions.baseUrl;
    return switch (error.type) {
      DioExceptionType.cancel => 'The request was cancelled.',
      DioExceptionType.receiveTimeout => 'The server at $url did not answer in time.',
      DioExceptionType.badCertificate => 'The server at $url has a certificate that is not valid.',
      _ => 'Cannot reach the server at $url.',
    };
  }

  static Map<String, dynamic>? _body(Object? data) {
    if (data is Map<String, dynamic>) return data;
    final text = switch (data) {
      List<int>() => utf8.decode(data, allowMalformed: true),
      String() => data,
      _ => '',
    };
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static Map<String, List<String>> _fieldErrors(Object? errors) {
    if (errors is! Map) return const {};
    return {for (final MapEntry(:key, :value) in errors.entries) key as String: List<String>.from(value as List)};
  }
}
