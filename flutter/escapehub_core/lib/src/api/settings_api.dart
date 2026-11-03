part of 'api_client.dart';

class SettingsApi {
  SettingsApi._(this._client);

  final ApiClient _client;

  Future<SettingsDto> get() => _client._get('/api/settings', SettingsDto.fromJson);

  Future<SettingsDto> update(UpdateSettingsRequest request) =>
      _client._put('/api/settings', SettingsDto.fromJson, request.toJson());
}
