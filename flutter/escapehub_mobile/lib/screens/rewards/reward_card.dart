import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formatting.dart';
import '../../providers.dart';

class RewardCard extends ConsumerWidget {
  const RewardCard({super.key, required this.reward, required this.balance});

  final LoyaltyRewardDto reward;
  final AsyncValue<int> balance;

  String _hint(int? missing) => switch (missing) {
    null when balance.hasError => 'Your balance did not load, so you cannot redeem now.',
    null => 'Your balance is loading.',
    final int count when count > 0 => 'You need ${formatPoints(count)} more.',
    _ => '',
  };

  Future<void> _redeem(BuildContext context, WidgetRef ref, int balance) async {
    final tabs = DefaultTabController.of(context);
    final api = ref.read(apiClientProvider);
    final loyalty = ref.read(loyaltyRevisionProvider.notifier);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Redeem reward',
      message:
          'Redeem ${reward.name} for ${formatPoints(reward.pointsCost)}? '
          'Your balance will be ${formatPoints(balance - reward.pointsCost)}.',
      confirmLabel: 'Redeem',
    );
    if (!confirmed || !context.mounted) return;
    try {
      final voucher = await api.loyalty.redeem(reward.id);
      loyalty.bump();
      tabs.animateTo(1);
      if (context.mounted) {
        showSuccessSnackBar(context, 'You redeemed ${reward.name}. Your voucher code is ${voucher.code}.');
      }
    } on ApiException catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final available = balance.value;
    final missing = available == null ? null : reward.pointsCost - available;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(reward.name, style: theme.textTheme.titleMedium)),
                Text(formatPoints(reward.pointsCost), style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${reward.rewardTypeName} · ${formatDiscount(isPercentage: reward.isPercentage, value: reward.value)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
            if (reward.description.isNotEmpty) ...[const SizedBox(height: 6), Text(reward.description)],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(_hint(missing), style: theme.textTheme.bodySmall)),
                FilledButton.tonal(
                  onPressed: missing == null || missing > 0 ? null : () => _redeem(context, ref, available!),
                  child: const Text('Redeem'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
