import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sign_out.dart';
import '../../widgets/brand_header.dart';

class ClientOnlyScreen extends ConsumerWidget {
  const ClientOnlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandHeader(),
                const SizedBox(height: 32),
                const Text(
                  'This application is for clients. Staff accounts sign in to the EscapeHub desktop application.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => signOut(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
