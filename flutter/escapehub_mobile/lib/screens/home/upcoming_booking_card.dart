import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';
import '../../widgets/booking_status_chip.dart';
import '../bookings/booking_detail_screen.dart';

class UpcomingBookingCard extends StatelessWidget {
  const UpcomingBookingCard({super.key, required this.booking, required this.onExplore});

  final BookingListItemDto? booking;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final upcoming = booking;
    return upcoming == null ? _NoBooking(onExplore: onExplore) : _NextBooking(booking: upcoming);
  }
}

class _NextBooking extends StatelessWidget {
  const _NextBooking({required this.booking});

  final BookingListItemDto booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => BookingDetailScreen.open(context, booking.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ApiImage(
                path: booking.roomImageUrl,
                label: booking.roomName,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your next escape', style: theme.textTheme.labelMedium),
                    Text(booking.roomName, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDay(booking.date)}, ${formatTimeRange(booking.startTime, booking.endTime)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    BookingStatusChip(status: booking.status, label: booking.statusName),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoBooking extends StatelessWidget {
  const _NoBooking({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined),
            const SizedBox(width: 16),
            const Expanded(child: Text('You have no upcoming bookings. Find a room for your next escape.')),
            TextButton(onPressed: onExplore, child: const Text('Explore')),
          ],
        ),
      ),
    );
  }
}
