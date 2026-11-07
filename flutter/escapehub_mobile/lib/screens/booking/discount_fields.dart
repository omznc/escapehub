import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formatting.dart';

class DiscountFields extends StatelessWidget {
  const DiscountFields({
    super.key,
    required this.options,
    required this.promotionId,
    required this.redemptionId,
    required this.serverErrors,
    required this.onPromotion,
    required this.onRedemption,
  });

  final AsyncValue<(List<PromotionDto>, List<RewardRedemptionDto>)> options;
  final int? promotionId;
  final int? redemptionId;
  final ServerErrors serverErrors;
  final ValueChanged<int?> onPromotion;
  final ValueChanged<int?> onRedemption;

  @override
  Widget build(BuildContext context) {
    return options.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('$error'),
      data: (data) {
        final (promotions, vouchers) = data;
        return Column(children: [_promotionField(promotions), const SizedBox(height: 16), _voucherField(vouchers)]);
      },
    );
  }

  Widget _promotionField(List<PromotionDto> promotions) {
    return DropdownButtonFormField<int?>(
      initialValue: promotionId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Promotion',
        prefixIcon: const Icon(Icons.local_offer_outlined),
        helperText: promotions.isEmpty ? 'No promotion is valid for this room now.' : null,
      ),
      items: [
        const DropdownMenuItem(child: Text('No promotion')),
        for (final promotion in promotions)
          DropdownMenuItem(
            value: promotion.id,
            child: Text(
              '${promotion.name} (${formatDiscount(isPercentage: promotion.isPercentage, value: promotion.discountValue)})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      validator: serverErrors.validator<int?>('promotionId'),
      onChanged: promotions.isEmpty ? null : onPromotion,
    );
  }

  Widget _voucherField(List<RewardRedemptionDto> vouchers) {
    return DropdownButtonFormField<int?>(
      initialValue: redemptionId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Voucher',
        prefixIcon: const Icon(Icons.confirmation_number_outlined),
        helperText: vouchers.isEmpty ? 'You have no unused vouchers. Redeem points in Rewards.' : null,
      ),
      items: [
        const DropdownMenuItem(child: Text('No voucher')),
        for (final voucher in vouchers)
          DropdownMenuItem(
            value: voucher.id,
            child: Text('${voucher.rewardName} -${voucher.code}', overflow: TextOverflow.ellipsis),
          ),
      ],
      validator: serverErrors.validator<int?>('redemptionId'),
      onChanged: vouchers.isEmpty ? null : onRedemption,
    );
  }
}
