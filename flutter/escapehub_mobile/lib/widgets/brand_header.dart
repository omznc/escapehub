import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.tagline = 'Escape rooms, booked in minutes'});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(Icons.vpn_key_outlined, size: 40, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 16),
        Text('EscapeHub', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(tagline, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
