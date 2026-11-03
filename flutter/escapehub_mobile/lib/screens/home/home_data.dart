import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class HomeData {
  const HomeData({
    required this.featured,
    required this.recommendations,
    required this.promotions,
    required this.balance,
    required this.upcoming,
  });

  final List<RoomListItemDto> featured;
  final List<RecommendationDto> recommendations;
  final List<PromotionDto> promotions;
  final LoyaltyBalanceDto balance;
  final BookingListItemDto? upcoming;
}

final homeProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  ref.watch(bookingsRevisionProvider);
  ref.watch(loyaltyRevisionProvider);
  ref.watch(reviewsRevisionProvider);
  final api = ref.watch(apiClientProvider);
  final [
    featured as Paged<RoomListItemDto>,
    recommendations as Paged<RecommendationDto>,
    promotions as Paged<PromotionDto>,
    balance as LoyaltyBalanceDto,
    upcoming as Paged<BookingListItemDto>,
  ] = await Future.wait<Object>([
    api.rooms.list(const RoomQuery(isActive: true, sortBy: RoomSort.rating, pageSize: 6)),
    api.recommendations.mine(pageSize: 5),
    api.promotions.active(pageSize: 5),
    api.loyalty.myBalance(),
    api.bookings.mine(upcoming: true, pageSize: 1),
  ]);
  return HomeData(
    featured: featured.items,
    recommendations: recommendations.items,
    promotions: promotions.items,
    balance: balance,
    upcoming: upcoming.items.firstOrNull,
  );
});
