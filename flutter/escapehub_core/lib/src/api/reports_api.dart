part of 'api_client.dart';

class ReportQuery {
  const ReportQuery({this.from, this.to, this.roomId, this.top, this.groupBy});

  final DateTime? from;
  final DateTime? to;
  final int? roomId;
  final int? top;
  final ReportGroupBy? groupBy;

  Map<String, Object?> toQuery() => {'from': from, 'to': to, 'roomId': roomId, 'top': top, 'groupBy': groupBy?.name};
}

class ReportsApi {
  ReportsApi._(this._client);

  final ApiClient _client;

  static final _fileName = RegExp(r'filename="?([^";]+)"?');

  Future<ReportResult<T>> _report<T>(ReportType type, ReportQuery query, T Function(Json json) parse) =>
      _client._get('/api/reports/${type.value}', (json) => ReportResult.fromJson(json, parse), query.toQuery());

  Future<ReportResult<BookingsReportRow>> bookings([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.bookings, query, BookingsReportRow.fromJson);

  Future<ReportResult<RevenueReportRow>> revenue([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.revenue, query, RevenueReportRow.fromJson);

  Future<ReportResult<OccupancyReportRow>> occupancy([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.occupancy, query, OccupancyReportRow.fromJson);

  Future<ReportResult<TopRoomReportRow>> topRooms([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.topRooms, query, TopRoomReportRow.fromJson);

  Future<ReportResult<TopClientReportRow>> topClients([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.topClients, query, TopClientReportRow.fromJson);

  Future<ReportResult<TopClientReportRow>> topClientsBySpending([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.topClientsBySpending, query, TopClientReportRow.fromJson);

  Future<ReportResult<RatingReportRow>> ratings([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.ratings, query, RatingReportRow.fromJson);

  Future<ReportResult<RedemptionReportRow>> loyaltyRedemptions([ReportQuery query = const ReportQuery()]) =>
      _report(ReportType.loyaltyRedemptions, query, RedemptionReportRow.fromJson);

  Future<ExportedFile> export(ReportType type, ExportFormat format, [ReportQuery query = const ReportQuery()]) async {
    final response = await _client._send(
      () => _client._dio.get<List<int>>(
        '/api/reports/${type.value}/export',
        queryParameters: ApiClient._query({...query.toQuery(), 'format': format.name}),
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    final disposition = response.headers.value('content-disposition') ?? '';
    return ExportedFile(
      bytes: Uint8List.fromList(response.data!),
      fileName: _fileName.firstMatch(disposition)?.group(1) ?? '${type.value}.${format.name}',
      contentType: response.headers.value(Headers.contentTypeHeader) ?? '',
    );
  }
}

class DashboardApi {
  DashboardApi._(this._client);

  final ApiClient _client;

  Future<DashboardStatsDto> stats() => _client._get('/api/dashboard/stats', DashboardStatsDto.fromJson);
}
