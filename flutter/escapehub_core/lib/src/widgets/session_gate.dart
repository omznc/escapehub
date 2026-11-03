import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers.dart';
import 'error_view.dart';

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.splash, required this.login, required this.home});

  final Widget splash;
  final Widget login;
  final Widget Function(UserDto user) home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      currentUserProvider.select((user) => user?.id),
      (previous, next) => Navigator.of(context).popUntil((route) => route.isFirst),
    );
    return ref
        .watch(sessionProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => splash,
          error: (error, _) => Scaffold(
            body: ErrorView(error: error, onRetry: () => ref.invalidate(sessionProvider)),
          ),
          data: (user) => user == null ? login : home(user),
        );
  }
}
