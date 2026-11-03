part of 'api_client.dart';

class SchedulesApi {
  SchedulesApi._(this._client);

  final ApiClient _client;

  Future<Paged<ScheduleDto>> list({
    int? roomId,
    DateTime? from,
    DateTime? to,
    SlotStatus? status,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) => _client._getPaged('/api/schedules', ScheduleDto.fromJson, {
    'roomId': roomId,
    'from': from,
    'to': to,
    'status': status?.value,
    'search': search,
    'page': page,
    'pageSize': pageSize,
  });

  Future<Paged<SlotDto>> slots({required int roomId, DateTime? from, DateTime? to, int page = 1, int pageSize = 100}) =>
      _client._getPaged('/api/schedules/slots', SlotDto.fromJson, {
        'roomId': roomId,
        'from': from,
        'to': to,
        'page': page,
        'pageSize': pageSize,
      });

  Future<ScheduleDto> create(ScheduleRequest request) =>
      _client._post('/api/schedules', ScheduleDto.fromJson, request.toJson());

  Future<ScheduleDto> update(int id, ScheduleRequest request) =>
      _client._put('/api/schedules/$id', ScheduleDto.fromJson, request.toJson());

  Future<void> delete(int id) => _client._delete('/api/schedules/$id');

  Future<GenerateSchedulesResponse> generate(GenerateSchedulesRequest request) =>
      _client._post('/api/schedules/generate', GenerateSchedulesResponse.fromJson, request.toJson());
}
