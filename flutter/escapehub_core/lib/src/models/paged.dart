import 'json.dart';

class Paged<T> {
  Paged.fromJson(Json json, T Function(Json json) parse)
    : items = readList(json['items'], parse),
      totalCount = json['totalCount'] as int,
      page = json['page'] as int,
      pageSize = json['pageSize'] as int;

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages => (totalCount / pageSize).ceil();

  bool get hasMore => page < totalPages;
}
