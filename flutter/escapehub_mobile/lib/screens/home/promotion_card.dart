import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';

class PromotionCard extends StatelessWidget {
  const PromotionCard({super.key, required this.promotion});

  final PromotionDto promotion;

  String get _rooms => promotion.appliesToAllRooms ? 'All rooms' : promotion.rooms.map((room) => room.name).join(', ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(promotion.name, style: theme.textTheme.titleSmall)),
                Text(
                  formatDiscount(isPercentage: promotion.isPercentage, value: promotion.discountValue),
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
            if (promotion.description.isNotEmpty) ...[const SizedBox(height: 6), Text(promotion.description)],
            const SizedBox(height: 6),
            Text(
              'Valid until ${formatDay(promotion.endDate)} - $_rooms',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
