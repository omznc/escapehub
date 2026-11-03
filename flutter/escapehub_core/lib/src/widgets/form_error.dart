import 'package:flutter/material.dart';

class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 20, color: colors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: colors.error)),
        ),
      ],
    );
  }
}
