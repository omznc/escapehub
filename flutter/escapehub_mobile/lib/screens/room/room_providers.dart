import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

final roomDetailProvider = FutureProvider.autoDispose.family<(RoomDto, Paged<ReviewDto>), int>((ref, roomId) async {
  ref.watch(reviewsRevisionProvider);
  final api = ref.watch(apiClientProvider);
  final [room as RoomDto, reviews as Paged<ReviewDto>] = await Future.wait<Object>([
    api.rooms.get(roomId),
    api.rooms.reviews(roomId, pageSize: 10),
  ]);
  return (room, reviews);
});

final slotsProvider = FutureProvider.autoDispose.family<List<SlotDto>, (int, DateTime)>((ref, key) async {
  ref.watch(bookingsRevisionProvider);
  final (roomId, date) = key;
  final page = await ref.watch(apiClientProvider).schedules.slots(roomId: roomId, from: date, to: date);
  return page.items;
});
