import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

Future<bool> runAction(BuildContext context, Future<void> Function() action, String success) async {
  try {
    await action();
    if (context.mounted) showSuccessSnackBar(context, success);
    return true;
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnackBar(context, error);
    return false;
  }
}

Future<T?> runLoad<T>(BuildContext context, Future<T> Function() load) async {
  try {
    return await load();
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnackBar(context, error);
    return null;
  }
}

Future<bool> confirmAndRun(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() action,
  required String success,
  bool destructive = false,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    destructive: destructive,
  );
  if (!confirmed || !context.mounted) return false;
  return runAction(context, action, success);
}
