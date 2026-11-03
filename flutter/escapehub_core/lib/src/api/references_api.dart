part of 'api_client.dart';

class ReferencesApi {
  ReferencesApi._(this._client);

  final ApiClient _client;

  Future<Paged<ReferenceDto>> list(
    ReferenceTable table, {
    int? countryId,
    String? search,
    ListSort? sortBy,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/${table.path}', table.parse, {
    'countryId': countryId,
    'search': search,
    'sortBy': sortBy?.value,
    'page': page,
    'pageSize': pageSize,
  });

  Future<ReferenceDto> create(ReferenceTable table, ReferenceRequest request) =>
      _client._post('/api/${table.path}', table.parse, request.toJson());

  Future<ReferenceDto> update(ReferenceTable table, int id, ReferenceRequest request) =>
      _client._put('/api/${table.path}/$id', table.parse, request.toJson());

  Future<void> delete(ReferenceTable table, int id) => _client._delete('/api/${table.path}/$id');
}
