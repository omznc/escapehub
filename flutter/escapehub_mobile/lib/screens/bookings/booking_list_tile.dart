import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';
import '../../widgets/booking_status_chip.dart';
import 'booking_detail_screen.dart';

class BookingListTile extends StatelessWidget {
  const BookingListTile({super.key, required this.booking, this.highlighted = false});

  final BookingListItemDto booking;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: highlighted ? theme.colorScheme.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => BookingDetailScreen.open(context, booking.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ApiImage(
                path: booking.roomImageUrl,
                label: booking.roomName,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.roomName, style: theme.textTheme.titleMedium),
                    Text('${formatDay(booking.date)}, ${booking.startTime}', style: theme.textTheme.bodySmall),
                    Text(
                      '${formatPlayerCount(booking.playerCount)} -${formatMoney(booking.totalPrice)}'
                      '${booking.isPaid ? ' - Paid' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    BookingStatusChip(status: booking.status, label: booking.statusName),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
