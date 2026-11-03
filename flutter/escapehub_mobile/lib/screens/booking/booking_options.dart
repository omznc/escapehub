import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookingOptionsProvider = FutureProvider.autoDispose.family<(List<PromotionDto>, List<RewardRedemptionDto>), int>((
  ref,
  roomId,
) async {
  final api = ref.watch(apiClientProvider);
  final [promotions as Paged<PromotionDto>, vouchers as Paged<RewardRedemptionDto>] = await Future.wait<Object>([
    api.promotions.active(roomId: roomId, pageSize: 100),
    api.loyalty.myRedemptions(isUsed: false, pageSize: 100),
  ]);
  return (promotions.items.where((promotion) => promotion.isCurrentlyValid).toList(), vouchers.items);
});
