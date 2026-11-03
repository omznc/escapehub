import 'package:flutter/material.dart';

class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.busy, required this.onPressed, this.icon});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    final leading = busy
        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : iconData == null
        ? null
        : Icon(iconData);
    return FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: busy ? null : onPressed,
      icon: leading,
      label: Text(label),
    );
  }
}
