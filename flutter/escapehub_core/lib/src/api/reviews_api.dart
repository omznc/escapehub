part of 'api_client.dart';

class ReviewQuery {
  const ReviewQuery({
    this.roomId,
    this.clientId,
    this.rating,
    this.minRating,
    this.from,
    this.to,
    this.includeHidden,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  final int? roomId;
  final int? clientId;
  final int? rating;
  final int? minRating;
  final DateTime? from;
  final DateTime? to;
  final bool? includeHidden;
  final String? search;
  final int page;
  final int pageSize;

  Map<String, Object?> toQuery() => {
    'roomId': roomId,
    'clientId': clientId,
    'rating': rating,
    'minRating': minRating,
    'from': from,
    'to': to,
    'includeHidden': includeHidden,
    'search': search,
    'page': page,
    'pageSize': pageSize,
  };
}

class ReviewsApi {
  ReviewsApi._(this._client);

  final ApiClient _client;

  Future<Paged<ReviewDto>> list([ReviewQuery query = const ReviewQuery()]) =>
      _client._getPaged('/api/reviews', ReviewDto.fromJson, query.toQuery());

  Future<Paged<ReviewDto>> mine({int? roomId, int page = 1, int pageSize = 20}) =>
      _client._getPaged('/api/reviews/me', ReviewDto.fromJson, {'roomId': roomId, 'page': page, 'pageSize': pageSize});

  Future<ReviewDto> create({required int roomId, required int rating, String? comment}) =>
      _client._post('/api/reviews', ReviewDto.fromJson, {'roomId': roomId, 'rating': rating, 'comment': comment});

  Future<ReviewDto> update(int id, {required int rating, String? comment}) =>
      _client._put('/api/reviews/$id', ReviewDto.fromJson, {'rating': rating, 'comment': comment});

  Future<void> delete(int id) => _client._delete('/api/reviews/$id');

  Future<void> hide(int id) => _client._command('/api/reviews/$id/hide');

  Future<void> unhide(int id) => _client._command('/api/reviews/$id/unhide');
}
