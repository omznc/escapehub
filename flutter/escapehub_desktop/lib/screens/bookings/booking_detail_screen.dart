import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/actions.dart';
import '../../widgets/pages.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/status_chip.dart';
import 'booking_result_dialog.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late Future<BookingDto> _booking = _load();

  BookingsApi get _api => ref.read(apiClientProvider).bookings;

  Future<BookingDto> _load() => _api.get(widget.bookingId);

  void _reload() => setState(() => _booking = _load());

  String _describe(BookingDto booking) =>
      'the booking of ${booking.clientName} for ${booking.roomName} on ${formatDate(booking.date)} at ${booking.startTime}';

  Future<void> _confirm(BookingDto booking) async {
    final done = await confirmAndRun(
      context,
      title: 'Confirm the booking',
      message: 'Do you want to confirm ${_describe(booking)}? The client gets a notification.',
      confirmLabel: 'Confirm',
      action: () => _api.confirm(booking.id),
      success: 'The booking was confirmed. The client gets a notification.',
    );
    if (done && mounted) _reload();
  }

  Future<void> _noShow(BookingDto booking) async {
    final done = await confirmAndRun(
      context,
      title: 'Mark as no-show',
      message: 'Do you want to mark ${_describe(booking)} as a no-show? You cannot undo this action.',
      confirmLabel: 'Mark as no-show',
      destructive: true,
      action: () => _api.markNoShow(booking.id),
      success: 'The booking was marked as a no-show.',
    );
    if (done && mounted) _reload();
  }

  Future<void> _reject(BookingDto booking) async {
    final reason = await showReasonDialog(
      context,
      title: 'Reject the booking',
      message: 'Do you want to reject ${_describe(booking)}? The client sees the reason. You cannot undo this action.',
      confirmLabel: 'Reject',
    );
    if (reason == null || !mounted) return;
    final done = await runAction(context, () => _api.reject(booking.id, reason), 'The booking was rejected.');
    if (done && mounted) _reload();
  }

  Future<void> _cancel(BookingDto booking) async {
    final reason = await showReasonDialog(
      context,
      title: 'Cancel the booking',
      message: 'Do you want to cancel ${_describe(booking)}? The client sees the reason. You cannot undo this action.',
      confirmLabel: 'Cancel the booking',
    );
    if (reason == null || !mounted) return;
    final done = await runAction(context, () => _api.cancel(booking.id, reason), 'The booking was cancelled.');
    if (done && mounted) _reload();
  }

  Future<void> _result(BookingDto booking, ResultMode mode) async {
    if (await showResultDialog(context, booking, mode) != null && mounted) _reload();
  }

  static String? _blocked(BookingDto booking, BookingAction action, String verb) => booking.allows(action)
      ? null
      : booking.blockedReason(action) ?? 'You cannot $verb a booking with the status ${booking.statusName}.';

  List<Widget> _actions(BookingDto booking) {
    final canEdit = booking.allows(BookingAction.editResult);
    final resultMode = canEdit ? ResultMode.edit : ResultMode.record;
    return [
      _ActionButton(
        label: 'Confirm',
        icon: Icons.check_circle_outline,
        reason: _blocked(booking, BookingAction.confirm, 'confirm'),
        onPressed: () => _confirm(booking),
      ),
      _ActionButton(
        label: 'Reject',
        icon: Icons.block,
        reason: _blocked(booking, BookingAction.reject, 'reject'),
        onPressed: () => _reject(booking),
      ),
      _ActionButton(
        label: 'Cancel',
        icon: Icons.event_busy_outlined,
        reason: booking.allows(BookingAction.cancel)
            ? null
            : booking.cancelBlockedReason ?? _blocked(booking, BookingAction.cancel, 'cancel'),
        onPressed: () => _cancel(booking),
      ),
      _ActionButton(
        label: 'Complete',
        icon: Icons.task_alt,
        reason: _blocked(booking, BookingAction.complete, 'complete'),
        onPressed: () => _result(booking, ResultMode.complete),
      ),
      _ActionButton(
        label: 'No-show',
        icon: Icons.person_off_outlined,
        reason: _blocked(booking, BookingAction.noShow, 'mark as no-show'),
        onPressed: () => _noShow(booking),
      ),
      _ActionButton(
        label: canEdit ? 'Edit result' : 'Record result',
        icon: Icons.emoji_events_outlined,
        reason: _blocked(booking, resultMode.action, 'record a result for'),
        onPressed: () => _result(booking, resultMode),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Booking details',
      body: FutureView<BookingDto>(
        future: _booking,
        onRetry: _reload,
        builder: (context, booking) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _BookingHeader(booking: booking, actions: _actions(booking)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _SessionColumn(booking: booking)),
                const SizedBox(width: 16),
                Expanded(child: _PriceColumn(booking: booking)),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Status history',
              child: _StatusHistory(history: booking.statusHistory),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.reason, required this.onPressed});

  final String label;
  final IconData icon;
  final String? reason;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final blocked = reason;
    return Tooltip(
      message: blocked ?? label,
      child: OutlinedButton.icon(onPressed: blocked == null ? onPressed : null, icon: Icon(icon), label: Text(label)),
    );
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.booking, required this.actions});

  final BookingDto booking;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApiImage(
              path: booking.roomImageUrl,
              label: booking.roomName,
              width: 160,
              height: 110,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(booking.roomName, style: theme.textTheme.headlineSmall),
                      const SizedBox(width: 12),
                      StatusChip(booking.statusName, Tone.ofBooking(booking.status)),
                      if (booking.isPaid) ...[const SizedBox(width: 8), const StatusChip('Paid', Tone.positive)],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.clientName}, ${formatDate(booking.date)} at ${booking.startTime}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text('Created on ${formatTimestamp(booking.createdAt)}', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionColumn extends StatelessWidget {
  const _SessionColumn({required this.booking});

  final BookingDto booking;

  @override
  Widget build(BuildContext context) {
    final notes = booking.notes;
    return Column(
      children: [
        SectionCard(
          title: 'Session',
          child: Column(
            children: [
              InfoRow(icon: Icons.meeting_room_outlined, label: 'Room', value: booking.roomName),
              InfoRow(icon: Icons.category_outlined, label: 'Theme', value: booking.themeName),
              InfoRow(icon: Icons.calendar_today_outlined, label: 'Date', value: formatDate(booking.date)),
              InfoRow(icon: Icons.schedule, label: 'Time', value: '${booking.startTime} to ${booking.endTime}'),
              InfoRow(icon: Icons.groups_outlined, label: 'Players', value: '${booking.playerCount}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Client and team',
          child: Column(
            children: [
              InfoRow(icon: Icons.person_outline, label: 'Client', value: booking.clientName),
              InfoRow(icon: Icons.mail_outline, label: 'Email', value: booking.clientEmail),
              InfoRow(
                icon: Icons.badge_outlined,
                label: 'Participants',
                value: booking.participantNames.isEmpty ? 'No names were entered' : booking.participantNames.join(', '),
              ),
              if (notes != null) InfoRow(icon: Icons.notes_outlined, label: 'Notes', value: notes),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.booking});

  final BookingDto booking;

  @override
  Widget build(BuildContext context) {
    final voucher = booking.voucherCode;
    return Column(
      children: [
        SectionCard(
          title: 'Price',
          child: Column(
            children: [
              InfoRow(icon: Icons.receipt_long_outlined, label: 'Subtotal', value: formatMoney(booking.subtotal)),
              InfoRow(icon: Icons.local_offer_outlined, label: 'Promotion', value: booking.promotionName ?? 'None'),
              InfoRow(
                icon: Icons.redeem_outlined,
                label: 'Voucher',
                value: voucher == null ? 'None' : '${booking.rewardName ?? 'Reward'} ($voucher)',
              ),
              InfoRow(
                icon: Icons.remove_circle_outline,
                label: 'Discount',
                value: formatMoney(booking.discountApplied),
              ),
              InfoRow(icon: Icons.payments_outlined, label: 'Total', value: formatMoney(booking.totalPrice)),
              InfoRow(
                icon: Icons.check_circle_outline,
                label: 'Payment',
                value: booking.isPaid
                    ? [
                        if (booking.paidAmount case final amount?) formatMoney(amount),
                        if (booking.paidAt case final paidAt?) formatTimestamp(paidAt),
                      ].join(' on ')
                    : 'Not paid',
              ),
              InfoRow(icon: Icons.loyalty_outlined, label: 'Points earned', value: '${booking.pointsEarned}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Result',
          child: _ResultView(result: booking.result),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final RoomResultDto? result;

  @override
  Widget build(BuildContext context) {
    final value = result;
    if (value == null) return const EmptyMessage('No result was recorded.', icon: Icons.emoji_events_outlined);
    String optional(int? number, String unit) => number == null ? 'Not recorded' : '$number$unit';
    return Column(
      children: [
        InfoRow(icon: Icons.door_back_door_outlined, label: 'Escaped', value: value.escaped ? 'Yes' : 'No'),
        InfoRow(icon: Icons.timer_outlined, label: 'Time', value: optional(value.completionTimeMinutes, ' min')),
        InfoRow(icon: Icons.lightbulb_outline, label: 'Hints used', value: optional(value.hintsUsed, '')),
        InfoRow(icon: Icons.emoji_events_outlined, label: 'Score', value: optional(value.score, ' of 100')),
        InfoRow(icon: Icons.notes_outlined, label: 'Manager notes', value: value.managerNotes ?? 'No notes'),
        InfoRow(
          icon: Icons.person_outline,
          label: 'Recorded by',
          value: '${value.recordedByName} on ${formatTimestamp(value.recordedAt)}',
        ),
      ],
    );
  }
}

class _StatusHistory extends StatelessWidget {
  const _StatusHistory({required this.history});

  final List<BookingStatusHistoryDto> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final entry in history.reversed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(entry.fromStatus == null ? entry.toStatus : '${entry.fromStatus} to ${entry.toStatus}'),
            subtitle: Text(
              [
                '${formatTimestamp(entry.changedAt)} by ${entry.changedByName ?? 'the system'}',
                if (entry.reason case final reason?) 'Reason: $reason',
              ].join('\n'),
            ),
            subtitleTextStyle: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
