part of 'api_client.dart';

class BookingsApi {
  BookingsApi._(this._client);

  final ApiClient _client;

  Future<Paged<BookingListItemDto>> list({
    BookingStatus? status,
    int? roomId,
    int? clientId,
    DateTime? from,
    DateTime? to,
    String? search,
    ListSort? sortBy,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/bookings', BookingListItemDto.fromJson, {
    'statusId': status?.id,
    'roomId': roomId,
    'clientId': clientId,
    'from': from,
    'to': to,
    'search': search,
    'sortBy': sortBy?.value,
    'page': page,
    'pageSize': pageSize,
  });

  Future<Paged<BookingListItemDto>> mine({bool upcoming = true, String? search, int page = 1, int pageSize = 20}) =>
      _client._getPaged('/api/bookings/me', BookingListItemDto.fromJson, {
        'upcoming': upcoming,
        'search': search,
        'page': page,
        'pageSize': pageSize,
      });

  Future<BookingDto> get(int id) => _client._get('/api/bookings/$id', BookingDto.fromJson);

  Future<BookingDto> create(CreateBookingRequest request) =>
      _client._post('/api/bookings', BookingDto.fromJson, request.toJson());

  Future<BookingQuoteDto> quote(CreateBookingRequest request) =>
      _client._post('/api/bookings/quote', BookingQuoteDto.fromJson, request.toJson());

  Future<BookingDto> confirm(int id) => _client._post('/api/bookings/$id/confirm', BookingDto.fromJson);

  Future<BookingDto> reject(int id, String reason) =>
      _client._post('/api/bookings/$id/reject', BookingDto.fromJson, {'reason': reason});

  Future<BookingDto> cancel(int id, String reason) =>
      _client._post('/api/bookings/$id/cancel', BookingDto.fromJson, {'reason': reason});

  Future<BookingDto> complete(int id, SaveRoomResultRequest result) =>
      _client._post('/api/bookings/$id/complete', BookingDto.fromJson, {'result': result.toJson()});

  Future<BookingDto> markNoShow(int id) => _client._post('/api/bookings/$id/no-show', BookingDto.fromJson);

  Future<PaymentStart> startPayment(int id) => _client._post('/api/bookings/$id/payment', PaymentStart.fromJson);

  Future<BookingDto> verifyPayment(int id) => _client._post('/api/bookings/$id/payment/verify', BookingDto.fromJson);

  Future<BookingDto> recordResult(int id, SaveRoomResultRequest result) =>
      _client._post('/api/bookings/$id/result', BookingDto.fromJson, result.toJson());

  Future<BookingDto> editResult(int id, SaveRoomResultRequest result) =>
      _client._put('/api/bookings/$id/result', BookingDto.fromJson, result.toJson());
}
