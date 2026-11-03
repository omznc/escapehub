import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sign_out.dart';
import '../../widgets/notifications_button.dart';
import 'avatar_editor.dart';
import 'change_password_screen.dart';
import 'profile_form.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), actions: const [NotificationsButton()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AvatarEditor(user: user),
          const SizedBox(height: 24),
          ProfileForm(user: user),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (context) => const ChangePasswordScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () => signOut(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
