import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import '../formatting.dart';
import 'rating_stars.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, required this.onTap});

  final RoomListItemDto room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApiImage(
                path: room.imageUrl,
                label: room.name,
                width: 96,
                height: 96,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${room.themeName} · ${room.difficultyName}', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    RatingSummary(rating: room.averageRating, count: room.reviewCount),
                    const SizedBox(height: 6),
                    _RoomFacts(room: room),
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

class _RoomFacts extends StatelessWidget {
  const _RoomFacts({required this.room});

  final RoomListItemDto room;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _Fact(icon: Icons.group_outlined, text: formatPlayers(room.minPlayers, room.maxPlayers)),
        _Fact(icon: Icons.payments_outlined, text: '${formatMoney(room.pricePerPerson)} / person'),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class RoomTile extends StatelessWidget {
  const RoomTile({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.subtitle,
    required this.onTap,
    this.footer,
  });

  final String name;
  final String? imageUrl;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApiImage(path: imageUrl, label: name, height: 112, width: double.infinity),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (footer case final footer?) ...[const SizedBox(height: 6), footer],
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
