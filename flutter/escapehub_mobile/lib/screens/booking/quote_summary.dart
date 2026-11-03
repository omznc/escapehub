import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';
import '../../widgets/form_message.dart';
import '../../widgets/info_row.dart';

class QuoteSummary extends StatelessWidget {
  const QuoteSummary({super.key, required this.quote, required this.error, required this.players});

  final BookingQuoteDto? quote;
  final String? error;
  final int players;

  @override
  Widget build(BuildContext context) {
    final current = quote;
    if (current == null) {
      return error == null ? const LinearProgressIndicator() : FormMessage(error);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            InfoRow(icon: Icons.group_outlined, label: 'Players', value: '$players'),
            InfoRow(icon: Icons.receipt_long_outlined, label: 'Subtotal', value: formatMoney(current.subtotal)),
            if (current.promotionDiscount > 0)
              InfoRow(
                icon: Icons.local_offer_outlined,
                label: current.promotionName ?? 'Promotion',
                value: '- ${formatMoney(current.promotionDiscount)}',
              ),
            if (current.voucherDiscount > 0)
              InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: current.rewardName ?? 'Voucher',
                value: '- ${formatMoney(current.voucherDiscount)}',
              ),
            const Divider(),
            InfoRow(icon: Icons.payments_outlined, label: 'Total', value: formatMoney(current.totalPrice)),
          ],
        ),
      ),
    );
  }
}
