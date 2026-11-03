import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

enum Tone {
  neutral(Color(0xFFE6E8EB), Color(0xFF3A4048)),
  positive(Color(0xFFDCEBDD), Color(0xFF1F4A25)),
  info(Color(0xFFDDE5F2), Color(0xFF1F3A5F)),
  pending(Color(0xFFF3E8CF), Color(0xFF5B4410)),
  negative(Color(0xFFF2DDDA), Color(0xFF6A231B));

  const Tone(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static Tone ofBooking(BookingStatus status) => switch (status) {
    BookingStatus.pending => Tone.pending,
    BookingStatus.confirmed => Tone.positive,
    BookingStatus.completed => Tone.info,
    BookingStatus.cancelled || BookingStatus.rejected || BookingStatus.noShow => Tone.negative,
  };

  static Tone ofSlot(SlotStatus status) => switch (status) {
    SlotStatus.available => Tone.positive,
    SlotStatus.booked => Tone.info,
    SlotStatus.past => Tone.neutral,
    SlotStatus.blocked => Tone.negative,
  };

  static Tone ofActive(bool isActive) => isActive ? Tone.positive : Tone.neutral;
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.tone, {super.key});

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tone.foreground)),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Icon(star <= rating ? Icons.star : Icons.star_border, size: 16, color: color),
      ],
    );
  }
}
