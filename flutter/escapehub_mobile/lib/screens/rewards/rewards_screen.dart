import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formatting.dart';
import '../../providers.dart';
import '../../widgets/notifications_button.dart';
import '../../widgets/paged_list_view.dart';
import 'reward_card.dart';
import 'transaction_tile.dart';
import 'voucher_card.dart';

final balanceProvider = FutureProvider.autoDispose<LoyaltyBalanceDto>((ref) {
  ref.watch(loyaltyRevisionProvider);
  return ref.watch(apiClientProvider).loyalty.myBalance();
});

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Rewards'), actions: const [NotificationsButton()]),
        body: Column(
          children: [
            const _BalanceCard(),
            const TabBar(
              tabs: [
                Tab(text: 'Catalog'),
                Tab(text: 'My vouchers'),
                Tab(text: 'History'),
              ],
            ),
            Expanded(child: TabBarView(children: [_Catalog(), _Vouchers(), _History()])),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balance = ref.watch(balanceProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: balance.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (balance) => Row(
              children: [
                Icon(Icons.loyalty_outlined, size: 36, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatPoints(balance.balance), style: theme.textTheme.headlineSmall),
                      Text('Earned ${balance.earnedTotal} - Spent ${balance.redeemedTotal}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Catalog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    final balance = ref.watch(balanceProvider).whenData((balance) => balance.balance);
    return PagedListView<LoyaltyRewardDto>(
      reloadKey: ref.watch(loyaltyRevisionProvider),
      fetch: (page) => api.loyalty.rewards(isActive: true, page: page),
      emptyIcon: Icons.card_giftcard_outlined,
      emptyMessage: 'There are no rewards in the catalog now.',
      itemBuilder: (context, reward) => RewardCard(reward: reward, balance: balance),
    );
  }
}

class _Vouchers extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    return PagedListView<RewardRedemptionDto>(
      reloadKey: ref.watch(loyaltyRevisionProvider),
      fetch: (page) => api.loyalty.myRedemptions(page: page),
      emptyIcon: Icons.confirmation_number_outlined,
      emptyMessage: 'You have no vouchers yet. Redeem points in the catalog to get one.',
      itemBuilder: (context, voucher) => VoucherCard(voucher: voucher),
    );
  }
}

class _History extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    return PagedListView<LoyaltyTransactionDto>(
      reloadKey: ref.watch(loyaltyRevisionProvider),
      fetch: (page) => api.loyalty.myTransactions(page: page),
      emptyIcon: Icons.receipt_long_outlined,
      emptyMessage: 'You have no points yet. Complete a booking to earn points.',
      spacing: 0,
      itemBuilder: (context, transaction) => TransactionTile(transaction: transaction),
    );
  }
}
