import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';

class VoucherCard extends StatelessWidget {
  const VoucherCard({super.key, required this.voucher});

  final RewardRedemptionDto voucher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usedAt = voucher.usedAt;
    final colors = theme.colorScheme;
    final (background, foreground) = voucher.isUsed
        ? (colors.surfaceContainerHighest, colors.onSurfaceVariant)
        : (colors.primaryContainer, colors.onPrimaryContainer);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(voucher.rewardName, style: theme.textTheme.titleMedium)),
                DecoratedBox(
                  decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      voucher.isUsed ? 'Used' : 'Not used',
                      style: theme.textTheme.labelMedium?.copyWith(color: foreground),
                    ),
                  ),
                ),
              ],
            ),
            Text(formatDiscount(isPercentage: voucher.isPercentage, value: voucher.value)),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SelectableText(
                  voucher.code,
                  style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              usedAt == null
                  ? 'Redeemed on ${formatDay(voucher.redeemedAt)} for ${formatPoints(voucher.pointsSpent)}'
                  : 'Used on ${formatDay(usedAt)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
