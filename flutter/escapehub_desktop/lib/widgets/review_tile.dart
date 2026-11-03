import 'package:flutter/material.dart';

import '../format.dart';
import 'status_chip.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.title,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isHidden,
    this.leading,
    this.trailing,
  });

  final String title;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final bool isHidden;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = comment;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Row(
        children: [
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          RatingStars(rating),
          if (isHidden) ...[const SizedBox(width: 12), const StatusChip('Hidden', Tone.neutral)],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text != null && text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(text)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(formatTimestamp(createdAt), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
      trailing: trailing,
    );
  }
}
