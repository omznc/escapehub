part of 'api_client.dart';

class PromotionsApi {
  PromotionsApi._(this._client);

  final ApiClient _client;

  Future<Paged<PromotionDto>> list({
    bool? isActive,
    int? roomId,
    bool? currentlyValid,
    String? search,
    ListSort? sortBy,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/promotions', PromotionDto.fromJson, {
    'isActive': isActive,
    'roomId': roomId,
    'currentlyValid': currentlyValid,
    'search': search,
    'sortBy': sortBy?.value,
    'page': page,
    'pageSize': pageSize,
  });

  Future<Paged<PromotionDto>> active({int? roomId, int page = 1, int pageSize = 20}) => _client._getPaged(
    '/api/promotions/active',
    PromotionDto.fromJson,
    {'roomId': roomId, 'page': page, 'pageSize': pageSize},
  );

  Future<PromotionDto> create(SavePromotionRequest request) =>
      _client._post('/api/promotions', PromotionDto.fromJson, request.toJson());

  Future<PromotionDto> update(int id, SavePromotionRequest request) =>
      _client._put('/api/promotions/$id', PromotionDto.fromJson, request.toJson());

  Future<void> delete(int id) => _client._delete('/api/promotions/$id');

  Future<void> activate(int id) => _client._command('/api/promotions/$id/activate');

  Future<void> deactivate(int id) => _client._command('/api/promotions/$id/deactivate');
}
