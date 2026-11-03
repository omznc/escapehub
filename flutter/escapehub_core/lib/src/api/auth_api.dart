part of 'api_client.dart';

class AuthApi {
  AuthApi._(this._client);

  final ApiClient _client;

  Future<AuthResponse> login(String username, String password) =>
      _client._post('/api/auth/login', AuthResponse.fromJson, {'username': username, 'password': password});

  Future<AuthResponse> desktopLogin(String username, String password) =>
      _client._post('/api/auth/desktop-login', AuthResponse.fromJson, {'username': username, 'password': password});

  Future<AuthResponse> register(RegisterRequest request) =>
      _client._post('/api/auth/register', AuthResponse.fromJson, request.toJson());

  Future<String> forgotPassword(String email) => _client._post('/api/auth/forgot-password', _message, {'email': email});

  Future<String> resetPassword({required String email, required String code, required String newPassword}) =>
      _client._post('/api/auth/reset-password', _message, {'email': email, 'code': code, 'newPassword': newPassword});

  Future<void> logout() => _client._command('/api/auth/logout');

  Future<UserDto> me() => _client._get('/api/auth/me', UserDto.fromJson);

  Future<UserDto> updateProfile(UpdateProfileRequest request) =>
      _client._put('/api/auth/profile', UserDto.fromJson, request.toJson());

  Future<String> changePassword({required String currentPassword, required String newPassword}) => _client._post(
    '/api/auth/change-password',
    _message,
    {'currentPassword': currentPassword, 'newPassword': newPassword},
  );
}
