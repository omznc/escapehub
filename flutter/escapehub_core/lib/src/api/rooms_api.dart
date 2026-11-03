part of 'api_client.dart';

class RoomQuery {
  const RoomQuery({
    this.themeId,
    this.difficultyLevelId,
    this.cityId,
    this.managerId,
    this.minPlayers,
    this.maxPlayers,
    this.partySize,
    this.minPrice,
    this.maxPrice,
    this.availableDate,
    this.isActive,
    this.sortBy,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  final int? themeId;
  final int? difficultyLevelId;
  final int? cityId;
  final int? managerId;
  final int? minPlayers;
  final int? maxPlayers;
  final int? partySize;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? availableDate;
  final bool? isActive;
  final RoomSort? sortBy;
  final String? search;
  final int page;
  final int pageSize;

  Map<String, Object?> toQuery() => {
    'themeId': themeId,
    'difficultyLevelId': difficultyLevelId,
    'cityId': cityId,
    'managerId': managerId,
    'minPlayers': minPlayers,
    'maxPlayers': maxPlayers,
    'partySize': partySize,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'availableDate': availableDate,
    'isActive': isActive,
    'sortBy': sortBy?.value,
    'search': search,
    'page': page,
    'pageSize': pageSize,
  };
}

class RoomsApi {
  RoomsApi._(this._client);

  final ApiClient _client;

  Future<Paged<RoomListItemDto>> list([RoomQuery query = const RoomQuery()]) =>
      _client._getPaged('/api/rooms', RoomListItemDto.fromJson, query.toQuery());

  Future<RoomDto> get(int id) => _client._get('/api/rooms/$id', RoomDto.fromJson);

  Future<RoomDto> create(SaveRoomRequest request) => _client._post('/api/rooms', RoomDto.fromJson, request.toJson());

  Future<RoomDto> update(int id, SaveRoomRequest request) =>
      _client._put('/api/rooms/$id', RoomDto.fromJson, request.toJson());

  Future<void> delete(int id) => _client._delete('/api/rooms/$id');

  Future<Paged<ReviewDto>> reviews(int id, {int page = 1, int pageSize = 20}) =>
      _client._getPaged('/api/rooms/$id/reviews', ReviewDto.fromJson, {'page': page, 'pageSize': pageSize});

  Future<RoomStatsDto> stats(int id, {DateTime? from, DateTime? to}) =>
      _client._get('/api/rooms/$id/stats', RoomStatsDto.fromJson, {'from': from, 'to': to});

  Future<void> archive(int id) => _client._command('/api/rooms/$id/archive');

  Future<void> restore(int id) => _client._command('/api/rooms/$id/restore');
}

class RoomScenariosApi {
  RoomScenariosApi._(this._client);

  final ApiClient _client;

  Future<Paged<RoomScenarioDto>> list({
    int? roomId,
    bool? isActive,
    String? search,
    ListSort? sortBy,
    int page = 1,
    int pageSize = 20,
  }) => _client._getPaged('/api/room-scenarios', RoomScenarioDto.fromJson, {
    'roomId': roomId,
    'isActive': isActive,
    'search': search,
    'sortBy': sortBy?.value,
    'page': page,
    'pageSize': pageSize,
  });

  Future<RoomScenarioDto> create(SaveRoomScenarioRequest request) =>
      _client._post('/api/room-scenarios', RoomScenarioDto.fromJson, request.toJson());

  Future<RoomScenarioDto> update(int id, SaveRoomScenarioRequest request) =>
      _client._put('/api/room-scenarios/$id', RoomScenarioDto.fromJson, request.toJson());

  Future<void> delete(int id) => _client._delete('/api/room-scenarios/$id');
}

class RecommendationsApi {
  RecommendationsApi._(this._client);

  final ApiClient _client;

  Future<Paged<RecommendationDto>> mine({int page = 1, int pageSize = 5}) =>
      _client._getPaged('/api/recommendations/me', RecommendationDto.fromJson, {'page': page, 'pageSize': pageSize});
}
