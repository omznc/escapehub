import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status, required this.label});

  final BookingStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      BookingStatus.pending => (colors.tertiaryContainer, colors.onTertiaryContainer),
      BookingStatus.confirmed => (colors.primaryContainer, colors.onPrimaryContainer),
      BookingStatus.completed => (colors.secondaryContainer, colors.onSecondaryContainer),
      _ => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
      ),
    );
  }
}
