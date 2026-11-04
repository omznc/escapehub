import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formatting.dart';
import '../../providers.dart';
import '../../widgets/booking_status_chip.dart';
import '../../widgets/section_header.dart';
import 'booking_detail_provider.dart';
import 'booking_sections.dart';
import 'cancel_booking_dialog.dart';
import 'payment_screen.dart';
import 'review_section.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  static Future<void> open(BuildContext context, int bookingId) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (context) => BookingDetailScreen(bookingId: bookingId)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookingDetailProvider(bookingId));
    final booking = detail.value?.$1;
    return Scaffold(
      appBar: AppBar(title: Text(booking?.roomName ?? 'Booking')),
      body: detail.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(bookingDetailProvider(bookingId))),
        data: (data) => _BookingBody(booking: data.$1, review: data.$2),
      ),
      bottomNavigationBar: booking == null ? null : _ActionBar(booking: booking),
    );
  }
}

class _BookingBody extends StatelessWidget {
  const _BookingBody({required this.booking, required this.review});

  final BookingDto booking;
  final ReviewDto? review;

  @override
  Widget build(BuildContext context) {
    final result = booking.result;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Header(booking: booking),
        const SectionHeader('Session'),
        SessionCard(booking: booking),
        const SectionHeader('Price'),
        PriceCard(booking: booking),
        if (result != null) ...[const SectionHeader('Result'), ResultCard(result: result)],
        if (booking.status == BookingStatus.completed) ...[
          const SectionHeader('Your review'),
          ReviewSection(booking: booking, review: review),
        ],
        const SectionHeader('Status history'),
        StatusHistory(entries: booking.statusHistory),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final BookingDto booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          ApiImage(
            path: booking.roomImageUrl,
            label: booking.roomName,
            width: 88,
            height: 88,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.roomName, style: theme.textTheme.titleLarge),
                Text(booking.themeName, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                BookingStatusChip(status: booking.status, label: booking.statusName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.booking});

  final BookingDto booking;

  bool get _isActive => booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(apiClientProvider);
    final refresh = ref.bookingsRefresh();
    final reason = await showCancelBookingDialog(context, booking);
    if (reason == null) return;
    try {
      await api.bookings.cancel(booking.id, reason);
      refresh();
      messenger.showSnackBar(
        SnackBar(content: Text('Your booking for ${booking.roomName} on ${formatDay(booking.date)} was cancelled.')),
      );
    } on ApiException catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(apiClientProvider);
    final refresh = ref.bookingsRefresh();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Pay for booking',
      message: 'Pay ${formatMoney(booking.totalPrice)} for ${booking.roomName} on ${formatDay(booking.date)}?',
      confirmLabel: 'Pay',
    );
    if (!confirmed || !context.mounted) return;
    try {
      final payment = await api.bookings.startPayment(booking.id);
      if (!context.mounted) return;
      await PaymentScreen.open(context, payment);
      final updated = await api.bookings.verifyPayment(booking.id);
      refresh();
      messenger.showSnackBar(
        SnackBar(content: Text(updated.isPaid ? 'Payment received' : 'Payment is not finished yet')),
      );
    } on ApiException catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isActive) return const SizedBox.shrink();
    final blockedReason = booking.cancelBlockedReason;
    final payReason = booking.isPaid || booking.canPay ? null : booking.payBlockedReason;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final reason in [if (!booking.canCancel) blockedReason, payReason].nonNulls)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(reason, style: TextStyle(color: colors.onSurfaceVariant)),
              ),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: booking.canCancel ? () => _cancel(context, ref) : null,
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Cancel booking'),
                  ),
                ),
                if (booking.canPay && !booking.isPaid)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () => _pay(context, ref),
                      icon: const Icon(Icons.payments_outlined),
                      label: Text('Pay ${formatMoney(booking.totalPrice)}'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
