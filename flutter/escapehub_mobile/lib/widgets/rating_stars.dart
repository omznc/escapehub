import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var star = 1; star <= 5; star++) Icon(_icon(star), size: size, color: color)],
    );
  }

  IconData _icon(int star) {
    if (rating >= star) return Icons.star;
    return rating >= star - 0.5 ? Icons.star_half : Icons.star_border;
  }
}

class RatingSummary extends StatelessWidget {
  const RatingSummary({super.key, required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    if (count == 0) return Text('No reviews yet', style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingStars(rating, size: 14),
        const SizedBox(width: 4),
        Text('${rating.toStringAsFixed(1)} ($count)', style: style),
      ],
    );
  }
}
