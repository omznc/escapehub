import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final LoyaltyTransactionDto transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = transaction.points >= 0;
    final title = transaction.description ?? transaction.type.value;
    final subtitle = [?transaction.roomName, formatTimestamp(transaction.createdAt)].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: positive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
        child: Icon(positive ? Icons.add : Icons.remove, color: theme.colorScheme.onSurface),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        '${positive ? '+' : ''}${transaction.points}',
        style: theme.textTheme.titleMedium?.copyWith(color: positive ? theme.colorScheme.primary : null),
      ),
    );
  }
}
