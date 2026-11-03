import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class ApiImage extends ConsumerWidget {
  const ApiImage({
    super.key,
    required this.path,
    required this.label,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.icon = Icons.image_outlined,
  });

  final String? path;
  final String label;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    final source = path;
    final url = source == null ? null : api.fileUrl(source);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? _placeholder(context)
            : Image.network(
                url,
                headers: api.headersFor(url),
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _placeholder(context),
              ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = label.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(2).map((word) => word[0]);
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: initials.isEmpty
            ? Icon(icon, color: colors.onSurfaceVariant)
            : FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    initials.join().toUpperCase(),
                    style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
      ),
    );
  }
}
