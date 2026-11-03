import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../room/reviews_section.dart';
import 'review_dialog.dart';

enum _ReviewAction { edit, delete }

class ReviewSection extends ConsumerWidget {
  const ReviewSection({super.key, required this.booking, required this.review});

  final BookingDto booking;
  final ReviewDto? review;

  Future<void> _write(BuildContext context, WidgetRef ref) async {
    final reviews = ref.read(reviewsRevisionProvider.notifier);
    final saved = await showReviewDialog(context, roomId: booking.roomId, roomName: booking.roomName, review: review);
    if (saved == null) return;
    reviews.bump();
    if (context.mounted) {
      showSuccessSnackBar(
        context,
        review == null
            ? 'Your review of ${booking.roomName} was published.'
            : 'Your review of ${booking.roomName} was updated.',
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ReviewDto review) async {
    final api = ref.read(apiClientProvider);
    final reviews = ref.read(reviewsRevisionProvider.notifier);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete review',
      message: 'Delete your review of ${booking.roomName}? You can write a new one later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await api.reviews.delete(review.id);
      reviews.bump();
      if (context.mounted) showSuccessSnackBar(context, 'Your review of ${booking.roomName} was deleted.');
    } on ApiException catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = review;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: current == null ? _writeButton(context, ref) : _existing(context, ref, current),
    );
  }

  Widget _writeButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: booking.canReview ? () => _write(context, ref) : null,
      icon: const Icon(Icons.rate_review_outlined),
      label: Text(booking.canReview ? 'Write a review' : 'Reviews are not available for this booking'),
    );
  }

  Widget _existing(BuildContext context, WidgetRef ref, ReviewDto current) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ReviewTile(
          review: current,
          title: 'You rated this room',
          trailing: PopupMenuButton<_ReviewAction>(
            tooltip: 'Review actions',
            onSelected: (action) => switch (action) {
              _ReviewAction.edit => _write(context, ref),
              _ReviewAction.delete => _delete(context, ref, current),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _ReviewAction.edit, child: Text('Edit review')),
              PopupMenuItem(value: _ReviewAction.delete, child: Text('Delete review')),
            ],
          ),
        ),
      ),
    );
  }
}
