import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RoomFilters = ({int? themeId, int? difficultyLevelId, int? partySize, RangeValues? price, DateTime? date});

const RoomFilters noFilters = (themeId: null, difficultyLevelId: null, partySize: null, price: null, date: null);

int activeFilterCount(RoomFilters filters) =>
    [filters.themeId, filters.difficultyLevelId, filters.partySize, filters.price, filters.date].nonNulls.length;

RoomQuery roomQuery(RoomFilters filters, RoomSort sort, String search, int page) => RoomQuery(
  isActive: true,
  themeId: filters.themeId,
  difficultyLevelId: filters.difficultyLevelId,
  partySize: filters.partySize,
  minPrice: filters.price?.start,
  maxPrice: filters.price?.end,
  availableDate: filters.date,
  sortBy: sort,
  search: search.isEmpty ? null : search,
  page: page,
);

const sortLabels = {
  RoomSort.rating: 'Highest rated',
  RoomSort.easiest: 'Easiest first',
  RoomSort.hardest: 'Hardest first',
  RoomSort.cheapest: 'Cheapest first',
  RoomSort.popular: 'Most popular',
};

final priceBoundsProvider = FutureProvider.autoDispose<RangeValues>((ref) async {
  final rooms = ref.watch(apiClientProvider).rooms;
  final cheapest = await rooms.list(const RoomQuery(isActive: true, sortBy: RoomSort.cheapest, pageSize: 1));
  if (cheapest.items.isEmpty) return const RangeValues(0, 0);
  final dearest = await rooms.list(
    RoomQuery(isActive: true, sortBy: RoomSort.cheapest, page: cheapest.totalCount, pageSize: 1),
  );
  final max = dearest.items.firstOrNull?.pricePerPerson ?? cheapest.items.first.pricePerPerson;
  return RangeValues(cheapest.items.first.pricePerPerson.floorToDouble(), max.ceilToDouble());
});
