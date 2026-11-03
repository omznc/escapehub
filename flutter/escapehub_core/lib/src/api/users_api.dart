part of 'api_client.dart';

class UsersApi {
  UsersApi._(this._client);

  final ApiClient _client;

  Future<Paged<UserDto>> list({
    String? role,
    bool? isActive,
    String? search,
    ListSort? sortBy,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/users', UserDto.fromJson, {
    'role': role,
    'isActive': isActive,
    'search': search,
    'sortBy': sortBy?.value,
    'page': page,
    'pageSize': pageSize,
  });

  Future<UserDto> create(CreateUserRequest request) => _client._post('/api/users', UserDto.fromJson, request.toJson());

  Future<UserDto> update(int id, UpdateUserRequest request) =>
      _client._put('/api/users/$id', UserDto.fromJson, request.toJson());

  Future<void> activate(int id) => _client._command('/api/users/$id/activate');

  Future<void> deactivate(int id) => _client._command('/api/users/$id/deactivate');

  Future<String> resetPassword(int id, String newPassword) =>
      _client._post('/api/users/$id/reset-password', _message, {'newPassword': newPassword});
}

class ClientsApi {
  ClientsApi._(this._client);

  final ApiClient _client;

  Future<Paged<UserDto>> list({bool? isActive, String? search, int page = 1, int pageSize = 20}) => _client._getPaged(
    '/api/clients',
    UserDto.fromJson,
    {'isActive': isActive, 'search': search, 'page': page, 'pageSize': pageSize},
  );

  Future<UserDto> get(int id) => _client._get('/api/clients/$id', UserDto.fromJson);

  Future<Paged<BookingListItemDto>> bookings(int id, {BookingStatus? status, int page = 1, int pageSize = 20}) =>
      _client._getPaged('/api/clients/$id/bookings', BookingListItemDto.fromJson, {
        'statusId': status?.id,
        'page': page,
        'pageSize': pageSize,
      });

  Future<LoyaltyBalanceDto> loyalty(int id) => _client._get('/api/clients/$id/loyalty', LoyaltyBalanceDto.fromJson);

  Future<Paged<LoyaltyTransactionDto>> transactions(
    int id, {
    TransactionType? type,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/clients/$id/transactions', LoyaltyTransactionDto.fromJson, {
    'type': type?.value,
    'from': from,
    'to': to,
    'page': page,
    'pageSize': pageSize,
  });
}
