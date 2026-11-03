import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> signOut(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showConfirmDialog(
    context,
    title: 'Sign out',
    message: 'Do you want to sign out of EscapeHub?',
    confirmLabel: 'Sign out',
  );
  if (!confirmed) return;
  try {
    await ref.read(sessionProvider.notifier).logout();
    messenger.showSnackBar(const SnackBar(content: Text('You signed out of EscapeHub.')));
  } on ApiException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('You signed out on this device. ${error.message}')));
  }
}
