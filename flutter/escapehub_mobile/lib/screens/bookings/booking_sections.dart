import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';
import '../../widgets/info_row.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );
  }
}

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.booking});

  final BookingDto booking;

  @override
  Widget build(BuildContext context) {
    final names = booking.participantNames;
    return _SectionCard(
      children: [
        InfoRow(icon: Icons.calendar_today_outlined, label: 'Date', value: formatDay(booking.date)),
        InfoRow(icon: Icons.schedule, label: 'Time', value: formatTimeRange(booking.startTime, booking.endTime)),
        InfoRow(icon: Icons.group_outlined, label: 'Players', value: '${booking.playerCount}'),
        if (names.isNotEmpty) InfoRow(icon: Icons.badge_outlined, label: 'Team', value: names.join('\n')),
        InfoRow(icon: Icons.event_note_outlined, label: 'Booked on', value: formatTimestamp(booking.createdAt)),
        if (booking.status == BookingStatus.completed)
          InfoRow(icon: Icons.loyalty_outlined, label: 'Points earned', value: formatPoints(booking.pointsEarned)),
      ],
    );
  }
}

class PriceCard extends StatelessWidget {
  const PriceCard({super.key, required this.booking});

  final BookingDto booking;

  @override
  Widget build(BuildContext context) {
    final voucher = [?booking.rewardName, ?booking.voucherCode].join(' · ');
    return _SectionCard(
      children: [
        InfoRow(icon: Icons.receipt_long_outlined, label: 'Subtotal', value: formatMoney(booking.subtotal)),
        if (booking.promotionName case final promotion?)
          InfoRow(icon: Icons.local_offer_outlined, label: 'Promotion', value: promotion),
        if (voucher.isNotEmpty) InfoRow(icon: Icons.confirmation_number_outlined, label: 'Voucher', value: voucher),
        if (booking.discountApplied > 0)
          InfoRow(icon: Icons.savings_outlined, label: 'Discount', value: '- ${formatMoney(booking.discountApplied)}'),
        const Divider(),
        InfoRow(icon: Icons.payments_outlined, label: 'Total', value: formatMoney(booking.totalPrice)),
      ],
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result});

  final RoomResultDto result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        InfoRow(
          icon: result.escaped ? Icons.lock_open : Icons.lock_outline,
          label: 'Escaped',
          value: result.escaped ? 'Yes, the team escaped' : 'No, the time ran out',
        ),
        if (result.completionTimeMinutes case final minutes?)
          InfoRow(icon: Icons.timer_outlined, label: 'Time', value: formatMinutes(minutes)),
        if (result.hintsUsed case final hints?)
          InfoRow(icon: Icons.lightbulb_outline, label: 'Hints used', value: '$hints'),
        if (result.score case final score?)
          InfoRow(icon: Icons.emoji_events_outlined, label: 'Score', value: '$score / 100'),
        InfoRow(icon: Icons.history, label: 'Recorded', value: formatTimestamp(result.recordedAt)),
      ],
    );
  }
}

class StatusHistory extends StatelessWidget {
  const StatusHistory({super.key, required this.entries});

  final List<BookingStatusHistoryDto> entries;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        for (final (index, entry) in entries.indexed) _HistoryEntry(entry: entry, isLast: index == entries.length - 1),
      ],
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.entry, required this.isLast});

  final BookingStatusHistoryDto entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [formatTimestamp(entry.changedAt), ?entry.changedByName].join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 6),
              Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
              if (!isLast) Expanded(child: VerticalDivider(width: 10, color: theme.colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.toStatus, style: theme.textTheme.titleSmall),
                  Text(details, style: theme.textTheme.bodySmall),
                  if (entry.reason case final reason?) Text('Reason: $reason'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
