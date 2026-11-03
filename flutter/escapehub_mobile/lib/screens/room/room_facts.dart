import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../../formatting.dart';
import '../../widgets/info_row.dart';

class RoomFacts extends StatelessWidget {
  const RoomFacts({super.key, required this.room});

  final RoomDto room;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            InfoRow(icon: Icons.category_outlined, label: 'Theme', value: room.themeName),
            InfoRow(icon: Icons.signal_cellular_alt, label: 'Difficulty', value: room.difficultyName),
            InfoRow(
              icon: Icons.group_outlined,
              label: 'Players',
              value: formatPlayers(room.minPlayers, room.maxPlayers),
            ),
            InfoRow(icon: Icons.timer_outlined, label: 'Duration', value: formatMinutes(room.durationMinutes)),
            InfoRow(
              icon: Icons.payments_outlined,
              label: 'Price',
              value: '${formatMoney(room.pricePerPerson)} per person',
            ),
            if (room.pricePerBooking > 0)
              InfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'Booking fee',
                value: formatMoney(room.pricePerBooking),
              ),
            if (room.cityName case final city?) InfoRow(icon: Icons.location_on_outlined, label: 'City', value: city),
            if (room.ageRecommendation case final age?) InfoRow(icon: Icons.cake_outlined, label: 'Age', value: age),
          ],
        ),
      ),
    );
  }
}
