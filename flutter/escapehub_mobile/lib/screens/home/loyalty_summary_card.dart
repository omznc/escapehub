import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';

class LoyaltySummaryCard extends StatelessWidget {
  const LoyaltySummaryCard({super.key, required this.balance, required this.onOpen});

  final LoyaltyBalanceDto balance;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(Icons.loyalty_outlined, color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text('${formatPoints(balance.balance)} available'),
        subtitle: Text('Earned ${balance.earnedTotal} · Spent ${balance.redeemedTotal}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
