import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int status, Object? data) {
  final options = RequestOptions(path: '/api/auth/register', baseUrl: 'http://localhost:5000');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  group('ApiException', () {
    test('keeps the backend message and the field errors', () {
      final error = ApiException.fromDio(
        _badResponse(400, {
          'message': 'Email is already in use.',
          'errors': {
            'email': ['Email is already in use.'],
          },
        }),
      );

      expect(error.statusCode, 400);
      expect(error.message, 'Email is already in use.');
      expect(error.fieldErrors['email'], ['Email is already in use.']);
      expect(error.fieldErrors['username'], isNull);
    });

    test('reads an error body that arrives as bytes', () {
      final error = ApiException.fromDio(
        _badResponse(403, utf8.encode('{"message":"Only administrators can export."}')),
      );

      expect(error.message, 'Only administrators can export.');
      expect(error.fieldErrors, isEmpty);
    });

    test('names the server address when the server cannot be reached', () {
      final error = ApiException.fromDio(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/rooms', baseUrl: 'http://localhost:5000'),
          reason: 'refused',
        ),
      );

      expect(error.statusCode, isNull);
      expect(error.message, 'Cannot reach the server at http://localhost:5000.');
    });
  });

  group('Validators', () {
    test('phone follows the backend format', () {
      final validate = Validators.phone();

      expect(validate(''), isNull);
      expect(validate('+387 61 234 567'), isNull);
      expect(validate('061/234-567'), isNull);
      expect(validate('abc'), 'Enter a phone number in the format +387 61 234 567.');
    });

    test('email gives the expected format', () {
      final validate = Validators.email();

      expect(validate('name@example.com'), isNull);
      expect(validate(''), 'Email is required.');
      expect(validate('name@'), 'Enter a valid email, for example name@example.com.');
    });

    test('password and decimal ranges', () {
      expect(Validators.password()('abc'), 'Password must have between 4 and 100 characters.');
      expect(Validators.password()('test'), isNull);
      expect(Validators.decimalRange('Price', min: 0, max: 1000)('25,50'), isNull);
      expect(
        Validators.decimalRange('Price', min: 0, max: 1000)('-1'),
        'Price must be a number between 0 and 1000, for example 25.50.',
      );
    });
  });

  test('ServerErrors shows a server error until the field changes', () {
    final errors = ServerErrors()
      ..apply(
        const ApiException(
          'Username is taken.',
          statusCode: 400,
          fieldErrors: {
            'username': ['Username is taken.'],
          },
        ),
      );
    final validate = errors.validator<String>('username', Validators.required('Username'));

    expect(validate(''), 'Username is required.');
    expect(validate('john'), 'Username is taken.');
    errors.remove('username');
    expect(validate('john'), isNull);
  });

  test('ServerErrors gives the message when no error belongs to a form field', () {
    final errors = ServerErrors()..validator<String>('username');

    ApiException conflict(Map<String, List<String>> fieldErrors) =>
        ApiException('The slot is no longer available.', statusCode: 409, fieldErrors: fieldErrors);

    expect(
      errors.apply(
        conflict({
          'scheduleId': ['The slot is no longer available.'],
        }),
      ),
      'The slot is no longer available.',
    );
    expect(
      errors.apply(
        conflict({
          'username': ['Username is taken.'],
        }),
      ),
      isNull,
    );
    expect(errors.apply(conflict(const {})), 'The slot is no longer available.');
  });

  test('ApiClient sends the token only to the API origin', () {
    final api = ApiClient(baseUrl: 'http://localhost:5000')..token = 'abc';

    expect(api.headersFor(api.fileUrl('/api/files/rooms/1/a.png')), {'Authorization': 'Bearer abc'});
    expect(api.headersFor('https://cdn.example.com/a.png'), isEmpty);
    expect(api.headersFor('http://localhost:8080/a.png'), isEmpty);
    api.close();
  });

  test('Paged computes the page count', () {
    final page = Paged.fromJson({
      'items': [
        {'count': 3},
      ],
      'totalCount': 41,
      'page': 1,
      'pageSize': 20,
    }, (json) => json['count'] as int);

    expect(page.items, [3]);
    expect(page.totalPages, 3);
    expect(page.hasMore, isTrue);
  });

  test('BookingDto reads dates, decimals and enums', () {
    final booking = BookingDto.fromJson({
      'id': 1,
      'roomId': 2,
      'roomName': 'The Vault',
      'roomImageUrl': null,
      'themeName': 'Heist',
      'scheduleId': 3,
      'date': '2026-10-12T00:00:00Z',
      'startTime': '18:30',
      'endTime': '19:30',
      'clientId': 4,
      'clientName': 'Ana Client',
      'clientPictureUrl': null,
      'statusId': 5,
      'status': 'No-show',
      'playerCount': 4,
      'totalPrice': 120,
      'hasResult': false,
      'createdAt': '2026-10-01T08:00:00Z',
      'clientEmail': 'ana@example.com',
      'subtotal': 130.5,
      'discountApplied': 10.5,
      'promotionId': null,
      'promotionName': null,
      'redemptionId': null,
      'voucherCode': null,
      'rewardName': null,
      'notes': null,
      'participantNames': ['Ana', 'Ben'],
      'result': null,
      'pointsEarned': 0,
      'canCancel': false,
      'cancelBlockedReason': 'The session is over.',
      'canReview': false,
      'allowedActions': ['no-show', 'record-result'],
      'blockedReasons': {'confirm': 'Only a pending booking can be confirmed.'},
      'statusHistory': [],
    });

    expect(booking.date, DateTime(2026, 10, 12));
    expect(booking.totalPrice, 120.0);
    expect(booking.status, BookingStatus.noShow);
    expect(booking.allows(BookingAction.recordResult), isTrue);
    expect(booking.allows(BookingAction.confirm), isFalse);
    expect(booking.blockedReason(BookingAction.confirm), 'Only a pending booking can be confirmed.');
    expect(booking.blockedReason(BookingAction.noShow), isNull);
    expect(formatDate(booking.date), '2026-10-12');
  });
}
