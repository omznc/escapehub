part of 'api_client.dart';

class FilesApi {
  FilesApi._(this._client);

  final ApiClient _client;

  Future<String> uploadProfilePicture(Uint8List bytes, String fileName) =>
      _client._upload('/api/files/profile-picture', bytes, fileName);

  Future<void> removeProfilePicture() => _client._delete('/api/files/profile-picture');

  Future<String> uploadRoomImage(int roomId, Uint8List bytes, String fileName) =>
      _client._upload('/api/files/rooms/$roomId', bytes, fileName);

  Future<void> removeRoomImage(int roomId) => _client._delete('/api/files/rooms/$roomId');
}
