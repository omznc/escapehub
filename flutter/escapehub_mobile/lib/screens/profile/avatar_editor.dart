import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class AvatarEditor extends ConsumerStatefulWidget {
  const AvatarEditor({super.key, required this.user});

  final UserDto user;

  @override
  ConsumerState<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends ConsumerState<AvatarEditor> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(ApiClient api) action, String success) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(apiClientProvider));
      await ref.read(sessionProvider.notifier).reload();
      if (mounted) showSuccessSnackBar(context, success);
    } on ApiException catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _run((api) => api.files.uploadProfilePicture(bytes, file.name), 'Your profile photo was updated.');
  }

  Future<void> _remove() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove photo',
      message: 'Remove your profile photo?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed) await _run((api) => api.files.removeProfilePicture(), 'Your profile photo was removed.');
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ApiImage(
              key: ValueKey(user.profilePictureUrl),
              path: user.profilePictureUrl,
              label: user.fullName,
              icon: Icons.person,
              width: 104,
              height: 104,
              borderRadius: BorderRadius.circular(52),
            ),
            if (_busy) const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 12),
        Text(user.fullName, style: theme.textTheme.titleLarge),
        Text(
          '@${user.username}',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Change photo'),
            ),
            if (user.profilePictureUrl != null)
              TextButton.icon(
                onPressed: _busy ? null : _remove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
