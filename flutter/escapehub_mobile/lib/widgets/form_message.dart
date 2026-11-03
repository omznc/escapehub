import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

class FormMessage extends StatelessWidget {
  const FormMessage(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: FormError(message));
  }
}
