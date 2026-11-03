import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/rating_stars.dart';

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({super.key, required this.reviews, required this.averageRating});

  final List<ReviewDto> reviews;
  final double averageRating;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const EmptyView(icon: Icons.rate_review_outlined, message: 'Nobody has reviewed this room yet.');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(averageRating.toStringAsFixed(1), style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(width: 12),
              RatingStars(averageRating, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          for (final review in reviews) ReviewTile(review: review),
        ],
      ),
    );
  }
}

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.title, this.trailing});

  final ReviewDto review;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = review.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title ?? review.clientName, style: theme.textTheme.titleSmall)),
              ?trailing,
            ],
          ),
          Row(
            children: [
              RatingStars(review.rating.toDouble(), size: 14),
              const SizedBox(width: 8),
              Text(formatDay(review.createdAt), style: theme.textTheme.bodySmall),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[const SizedBox(height: 4), Text(comment)],
        ],
      ),
    );
  }
}
